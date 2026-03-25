local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Red = require(ReplicatedStorage.Packages.Red)

local SellChoiceEvent = Red.Event("SellChoice", function(Value)
	return Value
end)

SellChoiceEvent:Client():Fire("Equipped") -- or "Inventory"
