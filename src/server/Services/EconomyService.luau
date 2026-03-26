--!strict
--!native

-- ====================== SERVICES ======================
local ServerScriptService = game:GetService("ServerScriptService")
local ServiceTypes = require(ServerScriptService.Server.Core.Types.ServiceTypes)
local DataService = require(ServerScriptService.ServerPackages.DataService).server

-- Initialize DataService with default template
DataService:init({
	template = {
		Cash = 0,
		RobloxInventory = {},
		Inventory = {},
		Slots = {},
		Index = {},
		LastSeen = 0,
		IncomePerSecond = 0,
		OfflineCap = 28800, -- 8 hours
	},
})

-- ====================== ECONOMY SERVICE ======================
local EconomyService = {}
EconomyService.__index = EconomyService

-- Player cache for fast lookups
local PlayerCache: { [Player]: ServiceTypes.Economy } = {}

-- ====================== CONSTRUCTOR ======================
function EconomyService.new(Player: Player): ServiceTypes.Economy
	local self = setmetatable({ Player = Player }, EconomyService) :: ServiceTypes.Economy
	PlayerCache[Player] = self
	return self
end

-- Placeholder for dependency injection
function EconomyService:SendDependencies(_Deps: { [string]: any }): ()
	return
end

-- ====================== CURRENCY METHODS ======================
function EconomyService:AddCurrency(Amount: number, Key: ServiceTypes.EconomyData): ()
	assert(Amount > 0, "[EconomyService] AddCurrency: Amount must be positive.")
	DataService:update(self.Player, Key, function(Current: number)
		return Current + Amount
	end)
end

function EconomyService:RemoveCurrency(Amount: number, Key: ServiceTypes.EconomyData): ()
	assert(Amount > 0, "[EconomyService] RemoveCurrency: Amount must be positive.")
	DataService:update(self.Player, Key, function(Current: number)
		return math.max(0, Current - Amount)
	end)
end

function EconomyService:SetCurrency(Amount: number, Key: ServiceTypes.EconomyData): ()
	assert(Amount >= 0, "[EconomyService] SetCurrency: Amount must be non-negative.")
	DataService:set(self.Player, Key, Amount)
end

function EconomyService:ResetCurrency(Key: ServiceTypes.EconomyData): ()
	DataService:set(self.Player, Key, 0)
end

-- ====================== TABLE METHODS ======================
local TableDefaults: { [string]: (string) -> any } = {
	Inventory = function(_)
		return true
	end,
	Index = function(_)
		return true
	end,
	Slots = function(Key)
		return Key
	end,
	RobloxInventory = function(Key)
		return Key
	end,
}

local TableRemoveDefaults: { [string]: any } = {
	Inventory = false,
	Index = false,
	Slots = nil,
	RobloxInventory = nil,
}

function EconomyService:AddToTable(TableKey: string, EntryKey: string): ()
	local defaultFunc = TableDefaults[TableKey]
	DataService:update(self.Player, { TableKey, EntryKey }, function(_)
		return if defaultFunc then defaultFunc(EntryKey) else nil
	end)
end

function EconomyService:RemoveFromTable(TableKey: string, EntryKey: string): ()
	local defaultValue = TableRemoveDefaults[TableKey]
	DataService:update(self.Player, { TableKey, EntryKey }, function(_)
		return if defaultValue ~= nil then defaultValue else nil
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
