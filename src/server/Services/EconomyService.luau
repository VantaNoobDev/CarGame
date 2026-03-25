--!strict
--!native
local ServerScriptService = game:GetService("ServerScriptService")
local ServiceTypes = require(ServerScriptService.Server.Core.Types.ServiceTypes)
local DataService = require(ServerScriptService.ServerPackages.DataService).server

DataService:init({
	template = {
		Cash = 0,
		RobloxInventory = {},
		Inventory = {},
		Slots = {},
		Index = {},
		LastSeen = 0,
		IncomePerSecond = 0,
		OfflineCap = 28800,
	},
})

-- ====================== ECONOMY SERVICE ======================

local EconomyService = {}
EconomyService.__index = EconomyService

local PlayerCache: { [Player]: ServiceTypes.Economy } = {}

function EconomyService.new(Player: Player): ServiceTypes.Economy
	local self = setmetatable({
		Player = Player,
	}, EconomyService) :: ServiceTypes.Economy

	PlayerCache[Player] = self
	return self
end

function EconomyService:SendDependencies(_Deps: { [string]: any }): ()
	return
end

-- ====================== CURRENCY ======================

function EconomyService:AddCurrency(Amount: number, Key: ServiceTypes.EconomyData): ()
	assert(Amount > 0, "Amount must be positive.")
	DataService:update(self.Player, Key, function(Current: number)
		return Current + Amount
	end)
end

function EconomyService:RemoveCurrency(Amount: number, Key: ServiceTypes.EconomyData): ()
	assert(Amount > 0, "Amount must be positive.")
	DataService:update(self.Player, Key, function(Current: number)
		return math.max(0, Current - Amount)
	end)
end

function EconomyService:SetCurrency(Amount: number, Key: ServiceTypes.EconomyData): ()
	assert(Amount >= 0, "Amount must be non-negative.")
	DataService:set(self.Player, Key, Amount)
end

function EconomyService:ResetCurrency(Key: ServiceTypes.EconomyData): ()
	DataService:set(self.Player, Key, 0)
end

-- ====================== TABLES ======================

function EconomyService:AddToTable(TableKey: string, EntryKey: string): ()
	DataService:update(self.Player, { TableKey, EntryKey }, function(Current: any)
		if TableKey == "Inventory" or TableKey == "Index" then
			return true
		elseif TableKey == "Slots" or TableKey == "RobloxInventory" then
			return EntryKey
		end
		return Current
	end)
end

function EconomyService:RemoveFromTable(TableKey: string, EntryKey: string): ()
	DataService:update(self.Player, { TableKey, EntryKey }, function(Current: any)
		if TableKey == "Inventory" or TableKey == "Index" then
			return false
		elseif TableKey == "Slots" or TableKey == "RobloxInventory" then
			return nil
		end
		return Current
	end)
end

function EconomyService:ClearTable(TableKey: string): ()
	DataService:set(self.Player, { TableKey }, {})
end

-- ====================== GETTERS ======================

function EconomyService:Get(Key: ServiceTypes.EconomyData): number | string | { any? }
	return DataService:get(self.Player, Key)
end

function EconomyService.GetByPlayer(Player: Player): ServiceTypes.Economy?
	return PlayerCache[Player]
end

-- ====================== LIFECYCLE ======================

function EconomyService:Destroy(): ()
	PlayerCache[self.Player] = nil
	self.Player = nil :: any
	setmetatable(self, nil)
end

return EconomyService
