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
		_connections = {} :: { RBXScriptConnection },
	}, StealingService) :: ServiceTypes.Stealing

	PlayerCache[Player] = self
	return self
end

function StealingService:SendDependencies(Deps: { [string]: any }): ()
	self._economy = Deps.Economy
	self._gear = Deps.Gear
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
	local Economy = PlayerCache[Interactor] and PlayerCache[Interactor]._economy :: any
	local Gear = PlayerCache[Interactor] and PlayerCache[Interactor]._gear :: any
	assert(Economy and Gear, "Player services not loaded.")

	-- Find the item on the stand
	local Item = Slot:FindFirstChildWhichIsA("Model")
	assert(Item, "No item found on stand.")

	local ItemKey = Item.Name

	-- Add to inventory and backpack
	Economy:AddToTable("Inventory", ItemKey)
	Gear:EquipGear("Usable", ItemKey, ItemKey, Item, 0)

	-- Remove from stand
	Item:Destroy()

	-- TODO: spawn monster from Base to chase Interactor
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
