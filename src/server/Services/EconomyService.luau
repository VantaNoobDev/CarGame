--!strict
--!native
local ServerScriptService = game:GetService("ServerScriptService")
local DataService = require(ServerScriptService.ServerPackages.DataService).server
local EconomyService = {}
EconomyService.__index = EconomyService

function EconomyService.new(Player: Player)
	return setmetatable({
		Player = Player,
	}, EconomyService)
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
		if InfoToBeChanged == "Inventory" then
			return not ValueThing
		end
		if InfoToBeChanged == "Slots" then
			return Value
		end
		if InfoToBeChanged == "RobloxInventory" then
			return Value
		end
		return ValueThing
	end)
end

function EconomyService:RemoveTable(InfoToBeChanged: string, InfoToBeRemoved: string, Value: string): ()
	DataService:update(self.Player, { InfoToBeChanged, InfoToBeRemoved }, function(ValueThing)
		if InfoToBeChanged == "Inventory" then
			return not ValueThing
		elseif InfoToBeChanged == "Slots" then
			return nil
		elseif InfoToBeChanged == "RobloxInventory" then
			return nil
		end
		return ValueThing
	end)
end

function EconomyService:ResetTable(InfoToBeChanged: string): ()
	DataService:update(self.Player, { InfoToBeChanged }, function(ValueThing)
		if InfoToBeChanged == "Inventory" then
			return {}
		elseif InfoToBeChanged == "Slots" then
			return {}
		elseif InfoToBeChanged == "RobloxInventory" then
			return {}
		end
		return ValueThing
	end)
end

function EconomyService:Get(Value: string): number | string | { any? }
	return DataService:get(self.Player, Value)
end

return EconomyService
