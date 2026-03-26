--!strict
--!native
local ServerScriptService = game:GetService("ServerScriptService")
local ServiceTypes = require(ServerScriptService.Server.Core.Types.ServiceTypes)

-- ====================== STEALING SERVICE ======================

local StealingService = {}
StealingService.__index = StealingService

local PlayerCache: { [Player]: ServiceTypes.Stealing } = {}

function StealingService.new(Player: Player): ServiceTypes.Stealing
	local self = setmetatable({
		Player = Player,
		_economy = nil :: any,
		_gear = nil :: any,
		_spawning = nil :: any,
		_connections = {} :: { RBXScriptConnection },
	}, StealingService) :: ServiceTypes.Stealing

	PlayerCache[Player] = self
	return self
end

function StealingService:SendDependencies(Deps: { [string]: any }): ()
	self._economy = Deps.Economy
	self._gear = Deps.Gear
	self._spawning = Deps.Spawning
end

-- ====================== SETUP ======================

function StealingService:Init(): ()
	local Map = workspace:WaitForChild("Map") :: Folder
	local BasesFolder = Map:WaitForChild("StealBases") :: Folder?
	if not BasesFolder then
		return
	end

	for _, Base in BasesFolder:GetChildren() do
		for _, Slot in Base:GetChildren() do
			local Spawn = Slot:FindFirstChild("Spawn")
			if not Spawn then
				continue
			end

			local Prompt = Instance.new("ProximityPrompt")
			Prompt.Parent = Spawn

			table.insert(
				self._connections,
				Prompt.Triggered:Connect(function(Interactor: Player)
					-- Only allow players whose services have been loaded
					if not PlayerCache[Interactor] then
						return
					end
					self:_OnSteal(Interactor, Slot)
				end)
			)
		end
	end
end

-- ====================== STEALING ======================

function StealingService:_OnSteal(Interactor: Player, Slot: Instance): ()
	local InteractorServices = PlayerCache[Interactor]
	assert(InteractorServices, "Player services not loaded.")

	local Economy = InteractorServices._economy :: any
	local Gear = InteractorServices._gear :: any
	local Spawning = InteractorServices._spawning :: any
	assert(Economy and Gear and Spawning, "Player services not loaded.")

	local Item = Slot:FindFirstChildWhichIsA("Model")
	assert(Item, "No item found on stand.")

	local ItemKey = Item.Name
	local StandId = Slot:GetAttribute("StandId") :: number
	assert(StandId, "Stand has no ID assigned.")

	-- Remove from stand
	Item:Destroy()

	-- TODO: put item in player's hands here

	-- Start chase — inventory is awarded/denied inside SpawningService
	Spawning:StartChase(Slot.Parent, Item, StandId, ItemKey)
end

-- ====================== GETTERS ======================

function StealingService.GetByPlayer(Player: Player): ServiceTypes.Stealing?
	return PlayerCache[Player]
end

-- ====================== LIFECYCLE ======================

function StealingService:Destroy(): ()
	for _, Connection in self._connections do
		Connection:Disconnect()
	end
	table.clear(self._connections)

	PlayerCache[self.Player] = nil
	self.Player = nil :: any
	self._economy = nil :: any
	self._gear = nil :: any
	setmetatable(self, nil)
end

return StealingService
