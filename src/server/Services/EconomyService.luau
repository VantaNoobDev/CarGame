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

function EconomyService:AddCurrency(Amount: number, Value: ServiceTypes.EconomyData): ()
	assert(Amount > 0, "Amount must be positive.")
	DataService:update(self.Player, Value, function(CurrentAmount)
		return CurrentAmount + Amount
	end)
end

function EconomyService:RemoveCurrency(Amount: number, Value: ServiceTypes.EconomyData): ()
	assert(Amount > 0, "Amount must be positive.") -- Fixed: was Amount < 0
	DataService:update(self.Player, Value, function(CurrentAmount)
		return CurrentAmount - Amount
	end)
end

function EconomyService:ResetCurrency(Value: ServiceTypes.EconomyData): ()
	DataService:set(self.Player, Value, 0)
end

function EconomyService:AddTable(InfoToBeChanged: string, InfoToBeAdded: string, Value: ServiceTypes.EconomyData): ()
	DataService:update(self.Player, { InfoToBeChanged, InfoToBeAdded }, function(ValueThing)
		if InfoToBeChanged == "Inventory" or InfoToBeChanged == "Index" then
			return not ValueThing
		end
		if InfoToBeChanged == "Slots" or InfoToBeChanged == "RobloxInventory" then
			return InfoToBeAdded -- Fixed: was Value
		end
		return ValueThing
	end)
end

function EconomyService:RemoveTable(
	InfoToBeChanged: ServiceTypes.EconomyData,
	InfoToBeRemoved: string,
	Value: ServiceTypes.EconomyData
): ()
	DataService:update(self.Player, { InfoToBeChanged, InfoToBeRemoved }, function(ValueThing)
		if InfoToBeChanged == "Inventory" or InfoToBeChanged == "Index" then
			return not ValueThing
		elseif InfoToBeChanged == "Slots" or InfoToBeChanged == "RobloxInventory" then
			return nil
		end
		return ValueThing
	end)
end

function EconomyService:ResetTable(InfoToBeChanged: ServiceTypes.EconomyData): ()
	DataService:update(self.Player, { InfoToBeChanged }, function(ValueThing)
		if InfoToBeChanged then
			return {}
		else
			return ValueThing
		end
	end)
end

function EconomyService:Get(Value: ServiceTypes.EconomyData): number | string | { any? }
	return DataService:get(self.Player, Value)
end

function EconomyService:GetPlayerData(Player: Player): ServiceTypes.Economy?
	return PlayerCache[Player]
end

function EconomyService:Destroy(): ()
	PlayerCache[self.Player] = nil
	self.Player = nil :: any
	setmetatable(self, nil)
end

return EconomyService
