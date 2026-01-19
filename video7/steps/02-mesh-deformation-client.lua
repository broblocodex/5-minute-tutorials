-- Step 02 - Mesh Deformation Client (LocalScript)
-- What: Client-side crack deformation using EditableMesh manipulation.
-- Why: Heavy vertex manipulation runs client-side for better performance.
-- Location: StarterPlayer > StarterPlayerScripts (keep for all subsequent steps)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AssetService = game:GetService("AssetService")

-- Some experiences provide Content via _G for CreateMeshPartAsync conversion.
-- Keep this flexible, but fail loudly with a helpful message if missing.
local Content = _G.Content or Content
assert(
	Content and type(Content) == "table" and type(Content.fromObject) == "function",
	"Missing Content.fromObject(). Ensure your environment provides Content (e.g., _G.Content) before using EditableMesh conversion."
)

local deformEvent = ReplicatedStorage:WaitForChild("CrateDeform")

--// Tuning
local CRACK_STRENGTH = 1.2

--// Cache (one editable mesh per crate part)
local editableByPart = {}

local function getOrCreateEditable(part: MeshPart)
	local entry = editableByPart[part]
	if entry and entry.part == part and part.Parent then
		return entry.editableMesh
	end

	local success, editableMesh = pcall(function()
		return AssetService:CreateEditableMeshAsync(part.MeshContent)
	end)
	
	if not success then
		warn("[CrateClient] Failed to create EditableMesh (likely memory limit):", editableMesh)
		return nil
	end
	
	editableByPart[part] = { part = part, editableMesh = editableMesh }
	return editableMesh
end


local function applyEditableMesh(part: MeshPart, editableMesh)
	local temp = AssetService:CreateMeshPartAsync(Content.fromObject(editableMesh))
	part:ApplyMesh(temp)
	temp:Destroy()
end

local function getBounds(editableMesh)
	local verts = editableMesh:GetVertices()
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)

	for _, vid in ipairs(verts) do
		local p = editableMesh:GetPosition(vid)
		minV = Vector3.new(math.min(minV.X, p.X), math.min(minV.Y, p.Y), math.min(minV.Z, p.Z))
		maxV = Vector3.new(math.max(maxV.X, p.X), math.max(maxV.Y, p.Y), math.max(maxV.Z, p.Z))
	end

	return minV, maxV, verts
end

local function clamp01(x)
	return math.max(0, math.min(1, x))
end

--// Deformation
-- Applies a "crack" effect along one side of the mesh.
local function crackSideStrong(part: MeshPart, editableMesh, axis: string, sign: number, seed: number, crackStrength: number?)
	if not editableMesh then return end
	math.randomseed(seed)

	local minV, maxV, verts = getBounds(editableMesh)
	local sizeVec = (maxV - minV)
	local size = sizeVec.Magnitude
	if size <= 0 then return end

	local bandOuter = size * 0.10
	local bandInner = size * 0.03
	local splitMax  = size * 0.08
	local stepMax   = size * 0.03
	local inwardMax = size * 0.02
	local jagMax    = size * 0.02

	-- Global strength multiplier (can be overridden by server in later steps)
	local S = (type(crackStrength) == "number") and crackStrength or CRACK_STRENGTH
	bandOuter *= (0.8 + 0.2 * S)  -- don't scale too much or cracks become huge
	bandInner *= (0.8 + 0.2 * S)
	splitMax  *= S
	stepMax   *= S
	inwardMax *= S
	jagMax    *= S

	-- side plane position
	local sideValue =
		(axis == "X" and ((sign == 1) and maxV.X or minV.X)) or
		(axis == "Y" and ((sign == 1) and maxV.Y or minV.Y)) or
		((sign == 1) and maxV.Z or minV.Z)

	local normal =
		(axis == "X" and Vector3.new(1,0,0)) or
		(axis == "Y" and Vector3.new(0,1,0)) or
		Vector3.new(0,0,1)

	local crackCount = math.random(2, 5)
	local cracks = {}

	for _ = 1, crackCount do
		local px = (minV.X + maxV.X) * 0.5 + (math.random() - 0.5) * sizeVec.X * 0.9
		local py = (minV.Y + maxV.Y) * 0.5 + (math.random() - 0.5) * sizeVec.Y * 0.9
		local pz = (minV.Z + maxV.Z) * 0.5 + (math.random() - 0.5) * sizeVec.Z * 0.9

		local p0 =
			(axis == "X" and Vector3.new(sideValue, py, pz)) or
			(axis == "Y" and Vector3.new(px, sideValue, pz)) or
			Vector3.new(px, py, sideValue)

		local dx, dy, dz = (math.random() - 0.5), (math.random() - 0.5), (math.random() - 0.5)
		if axis == "X" then dx = 0 end
		if axis == "Y" then dy = 0 end
		if axis == "Z" then dz = 0 end

		local d = Vector3.new(dx, dy, dz)
		if d.Magnitude < 1e-4 then
			d = (axis == "Z") and Vector3.new(1,0,0) or Vector3.new(0,0,1)
		end
		d = d.Unit

		local splitDir = d:Cross(normal)
		if splitDir.Magnitude < 1e-4 then
			splitDir = (axis == "Z") and Vector3.new(0,1,0) or Vector3.new(1,0,0)
		end
		splitDir = splitDir.Unit

		local crackStrength = (0.7 + math.random() * 0.6) * S
		table.insert(cracks, { p0 = p0, d = d, splitDir = splitDir, strength = crackStrength })
	end

	local moved = 0

	for _, vid in ipairs(verts) do
		local p = editableMesh:GetPosition(vid)

		local distToSide =
			(axis == "X" and math.abs(p.X - sideValue)) or
			(axis == "Y" and math.abs(p.Y - sideValue)) or
			math.abs(p.Z - sideValue)

		if distToSide > bandOuter then
			continue
		end

		local bestW = 0
		local bestOffset = Vector3.zero

		for _, c in ipairs(cracks) do
			local v = (p - c.p0)
			local lineDist = (v:Cross(c.d)).Magnitude

			if lineDist <= bandOuter then
				local wOuter = clamp01(1 - (lineDist / bandOuter))
				local wInner = clamp01(1 - (lineDist / bandInner))

				local sideSign = (v:Dot(c.splitDir) >= 0) and 1 or -1

				local split = c.splitDir * (splitMax * wOuter * sideSign * c.strength)
				local step  = normal * (stepMax * wInner * sideSign * c.strength) * 0.6
				local inward = (-normal * sign) * (inwardMax * wOuter * c.strength)

				local jag = Vector3.new(
					(math.random() - 0.5) * jagMax,
					(math.random() - 0.5) * jagMax,
					(math.random() - 0.5) * jagMax
				) * (wOuter * 0.7)

				local offset = split + step + inward + jag

				if wOuter > bestW then
					bestW = wOuter
					bestOffset = offset
				end
			end
		end

		if bestW > 0 then
			editableMesh:SetPosition(vid, p + bestOffset)
			moved += 1
		end
	end

	applyEditableMesh(part, editableMesh)
	print(("Cracks moved verts: %d | strength: %.2f | %s %d")
		:format(moved, S, axis, sign))
end

-- Step 02: Listen for deformation events from server
deformEvent.OnClientEvent:Connect(function(cratePart, axis, sign, seed, crackStrength)
	if not (cratePart and cratePart:IsA("MeshPart")) then return end
	if type(axis) ~= "string" or type(sign) ~= "number" or type(seed) ~= "number" then return end

	local editableMesh = getOrCreateEditable(cratePart)
	if not editableMesh then return end
	crackSideStrong(cratePart, editableMesh, axis, sign, seed, crackStrength)
end)