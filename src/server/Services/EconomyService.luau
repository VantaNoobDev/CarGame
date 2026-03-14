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

function EconomyService.new(Player: Player): ServiceTypes.Economy
	return setmetatable({
		Player = Player,
	}, EconomyService) :: any
end

function EconomyService:AddCurrency(Amount: number, Value: string): ()
	DataService:update(self.Player, Value, function(CurrentAmount)
		return CurrentAmount + math.abs(Amount)
	end)
end

function EconomyService:RemoveCurrency(Amount: number, Value: string): ()
	DataService:update(self.Player, Value, function(CurrentAmount)
		return CurrentAmount - math.abs(Amount)
	end)
end

function EconomyService:ResetCurrency(Value: string): ()
	DataService:set(self.Player, Value, 0)
end

function EconomyService:AddTable(InfoToBeChanged: string, InfoToBeAdded: string, Value: string): ()
	DataService:update(self.Player, { InfoToBeChanged, InfoToBeAdded }, function(ValueThing)
		if InfoToBeChanged == "Inventory" or InfoToBeChanged == "Index" then
			return not ValueThing
		end
		if InfoToBeChanged == "Slots" or InfoToBeChanged == "RobloxInventory" then
			return Value
		end
		return ValueThing
	end)
end

function EconomyService:RemoveTable(InfoToBeChanged: string, InfoToBeRemoved: string, Value: string): ()
	DataService:update(self.Player, { InfoToBeChanged, InfoToBeRemoved }, function(ValueThing)
		if InfoToBeChanged == "Inventory" or InfoToBeChanged == "Index" then
			return not ValueThing
		elseif InfoToBeChanged == "Slots" or InfoToBeChanged == "RobloxInventory" then
			return nil
		end
		return ValueThing
	end)
end

function EconomyService:ResetTable(InfoToBeChanged: string): ()
	DataService:update(self.Player, { InfoToBeChanged }, function(ValueThing)
		if InfoToBeChanged then
			return {}
		else
			return ValueThing
		end
	end)
end

function EconomyService:Get(Value: string): number | string | { any? }
	return DataService:get(self.Player, Value)
end

return EconomyService
