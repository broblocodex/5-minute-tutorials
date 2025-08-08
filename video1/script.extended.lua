-- Chameleon Block (extended variations)
-- Adds: per-character debounce, optional sound, RemoteEvent broadcast, and a simple quest gate via Player attribute.

local Players = game:GetService("Players")

local part = script.Parent
assert(part and part:IsA("BasePart"), "Place this script inside a Part")

-- Config
local COLORS = {
	BrickColor.new("Bright red"),
	BrickColor.new("Bright blue"),
	BrickColor.new("Bright green"),
	BrickColor.new("Bright yellow"),
}
local TOUCH_DEBOUNCE = 0.15 -- seconds between touches from the same character
local ENABLE_SOUND = false
local CLICK_RANGE = 32
local SET_ATTRIBUTES = true -- write attributes so other scripts can react
local STORE_LAST_USER = true -- also store LastUserId of the player who triggered

-- Optional attachments (create them in Studio or via code)
-- 1) Sound: parent a Sound under the part and set its SoundId; it will play on change when ENABLE_SOUND = true
local changeSound = part:FindFirstChildOfClass("Sound")
-- 2) RemoteEvent: create under part named "ColorChanged" to notify clients (e.g., for client VFX)
local remote = part:FindFirstChild("ColorChanged")

-- State
local idx = 1
part.BrickColor = COLORS[idx]
if SET_ATTRIBUTES then
	part:SetAttribute("ColorIndex", idx)
end

-- Helpers
local function canUse(player)
	-- Simple quest gate: allow only when player:GetAttribute("QuestReady") == true (or attribute not present)
	if not player then return true end
	local flag = player:GetAttribute("QuestReady")
	return flag == nil or flag == true
end

local function cycle(instigator)
	idx += 1
	if idx > #COLORS then idx = 1 end
	part.BrickColor = COLORS[idx]
	if SET_ATTRIBUTES then
		part:SetAttribute("ColorIndex", idx)
		if STORE_LAST_USER and instigator then
			part:SetAttribute("LastUserId", instigator.UserId)
		end
	end
	if ENABLE_SOUND and changeSound then
		changeSound:Play()
	end
	if remote then
		remote:FireAllClients(part, idx)
	end
end

-- Debounce per character so one body part doesn't spam multiple hits
local lastTouch = {}

local function onTouched(hit)
	local character = hit.Parent
	if not character then return end
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local player = Players:GetPlayerFromCharacter(character)
	if not canUse(player) then return end

	local now = os.clock()
	local last = lastTouch[character]
	if last and (now - last) < TOUCH_DEBOUNCE then return end
	lastTouch[character] = now

	cycle(player)
end

local touchedConn = part.Touched:Connect(onTouched)

local clickDetector = Instance.new("ClickDetector")
clickDetector.MaxActivationDistance = CLICK_RANGE
clickDetector.Parent = part
-- Pass the Player to cycle so we can store LastUserId when enabled
clickDetector.MouseClick:Connect(function(player)
	if not canUse(player) then return end
	cycle(player)
end)

-- Cleanup connection when the part is removed from the world
part.AncestryChanged:Connect(function(_, parent)
	if parent == nil and touchedConn then
		touchedConn:Disconnect()
		touchedConn = nil
	end
end)
