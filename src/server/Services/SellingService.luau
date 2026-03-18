--!strict
--!native
local EconomyService = require(script.Parent.EconomyService)
local GearService = require(script.Parent.GearService)

local Sell: Model | Folder | BasePart
local SellingService = {}

local Conn: RBXScriptConnection

function SellingService.AddSell(SellChosen: Model | Folder | BasePart): ()
	if SellChosen then
		Sell = SellChosen
	end
end

function SellingService:Init()
	if Sell then
		local Prompt = Sell:WaitForChild("Stand") :: ProximityPrompt
		assert(Prompt, "Selling part from prompt not found!")

		local Connection = Prompt.Triggered:Connect(function(Player: Player) end) -- No shop npc?
		Conn = Connection

		Sell.ChildRemoved:Connect(function(Part: Instance)
			if Part.Name == "Stand" then
				Conn:Disconnect()
			end
		end)
	end
end

return SellingService
