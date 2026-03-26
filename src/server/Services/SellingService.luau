--!strict
--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Red = require(ReplicatedStorage.Packages.Red)
local ServiceTypes = require(ServerScriptService.Server.Core.Types.ServiceTypes)

-- ====================== EVENTS ======================

local SellPromptEvent = Red.Event("SellPrompt", function(Value: any)
	return Value
end)

local SellChoiceEvent = Red.Event("SellChoice", function(Value: any)
	return Value
end)
-- ====================== SELLING SERVICE ======================

local SellingService = {}
SellingService.__index = SellingService

local PlayerCache: { [Player]: ServiceTypes.Selling } = {}

function SellingService.new(Player: Player): ServiceTypes.Selling
	local self = setmetatable({
		Player = Player,
		_economy = nil :: any,
		_gear = nil :: any,
		_stand = nil :: Instance?,
		_connections = {} :: { RBXScriptConnection },
	}, SellingService) :: ServiceTypes.Selling

	PlayerCache[Player] = self
	return self
end

function SellingService:SendDependencies(Deps: { [string]: any }): ()
	self._economy = Deps.Economy
	self._gear = Deps.Gear
end

-- ====================== PRICE ======================

-- TODO: replace with real item definitions once ready
local function GetItemPrice(_ItemKey: string): number
	return 10 -- placeholder
end

-- ====================== STAND ======================

function SellingService:AssignStand(Stand: Model | Folder | BasePart): ()
	assert(not self._stand, "Player already has a stand assigned.")
	assert(Stand, "Stand is nil.")
	self._stand = Stand
	self:_SetupPrompt()
end

function SellingService:_SetupPrompt(): ()
	local Stand = self._stand
	assert(Stand, "No stand assigned.")

	local Prompt = Stand:WaitForChild("Stand") :: ProximityPrompt
	assert(Prompt, "ProximityPrompt not found on stand.")

	table.insert(
		self._connections,
		Prompt.Triggered:Connect(function(Interactor: Player)
			self:_OnPromptTriggered(Interactor)
		end)
	)

	table.insert(
		self._connections,
		Stand.ChildRemoved:Connect(function(Part: Instance)
			if Part.Name == "Stand" then
				self:_TeardownPrompt()
			end
		end)
	)
end

function SellingService:_OnPromptTriggered(Interactor: Player): ()
	local Economy = self._economy :: any
	local Gear = self._gear :: any

	-- Fire client to show sell choice UI
	SellPromptEvent:Server():Fire(Interactor, {
		Equipped = Gear:GetEquipped(),
		Inventory = Economy:Get("Inventory"),
	})

	-- Wait for client's choice
	SellChoiceEvent:Server():On(function(Player: Player, Choice: string)
		if Player ~= Interactor then
			return
		end

		if Choice == "Equipped" then
			self:_SellEquipped()
		elseif Choice == "Inventory" then
			self:_SellInventory()
		end
	end)
end

function SellingService:_TeardownPrompt(): ()
	for _, Connection in self._connections do
		Connection:Disconnect()
	end
	table.clear(self._connections)
	self._stand = nil
end

-- ====================== SELLING ======================

function SellingService:_SellEquipped(): ()
	local Gear = self._gear :: any
	local Economy = self._economy :: any

	local Equipped: string = Gear:GetEquipped()
	assert(Equipped ~= "", "No gear is currently equipped.")

	local Price = GetItemPrice(Equipped)
	Gear:UnEquipGear(Equipped)
	Economy:AddCurrency(Price, "Cash")
end

function SellingService:_SellInventory(): ()
	local Economy = self._economy :: any
	local Inventory: { [string]: any } = Economy:Get("Inventory")
	local Total = 0

	for ItemKey in Inventory do
		Total += GetItemPrice(ItemKey)
		Economy:RemoveFromTable("Inventory", ItemKey)
	end

	Economy:AddCurrency(Total, "Cash")
end

-- ====================== GETTERS ======================

function SellingService.GetByPlayer(Player: Player): ServiceTypes.Selling?
	return PlayerCache[Player]
end

-- ====================== LIFECYCLE ======================

function SellingService:Destroy(): ()
	self:_TeardownPrompt()

	PlayerCache[self.Player] = nil
	self.Player = nil :: any
	self._economy = nil :: any
	self._gear = nil :: any
	setmetatable(self, nil)
end

return SellingService
