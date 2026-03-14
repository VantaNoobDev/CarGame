--!strict
--!native
local RunService = game:GetService("RunService")
local PlayersTable = {}

local PromptTable: { [number]: ProximityPrompt } = {}

local CurrentPrompt: number = 1

local Connections = {}

local StealingService = {}
StealingService.__index = StealingService

function StealingService:init()
	local Map = workspace:WaitForChild("Map") :: Folder
	local BasesFolder = Map:WaitForChild("StealBases") :: Folder?
	if BasesFolder then
		for _, Bases in pairs(BasesFolder:GetChildren()) do
			for _, Slots in pairs(Bases:GetChildren()) do
				local Spawn = Slots:FindFirstChild("Spawn")
				if Spawn then
					local Proximity = Instance.new("ProximityPrompt")
					Proximity.Parent = Spawn
					PromptTable[CurrentPrompt] = Proximity
				end
			end
		end
	end
end

function StealingService:NewPlayer(UserId: number | unknown)
	assert(UserId, "No user id found.")
	table.insert(PlayersTable, UserId)
end

local function Steal(Player: Player): () end

local LastTable = {}

RunService.Heartbeat:Connect(function()
	if LastTable ~= PlayersTable then
		if Connections[1] then
			task.cancel(Connections[1])
		end
		LastTable = PlayersTable
		local Connection = task.spawn(function()
			for _, Prompt in pairs(PromptTable) do
				if Prompt:IsA("ProximityPrompt") then
					Prompt.Triggered:Connect(function(WhoTriggered: Player)
						if table.find(PlayersTable, WhoTriggered.UserId) then
							task.spawn(Steal, WhoTriggered)
						end
					end)
				end
			end
		end)
		Connections[1] = Connection
	else
		return
	end
end)

return StealingService
