--!strict
--!native
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Red = require(ReplicatedStorage.Packages.Red)
local ServiceTypes = require(ServerScriptService.Server.Core.Types.ServiceTypes)

-- ====================== SHOP SERVICE ======================

local ShopService = {}
ShopService.__index = ShopService

local PlayerCache: { [Player]: ServiceTypes.Shop } = {}

local OpenShopEvent = Red.Event("OpenShop", function(Value: any)
	return Value
end)

function ShopService.new(Player: Player): ServiceTypes.Shop
	local self = setmetatable({
		Player = Player,
		_economy = nil :: any,
		_gear = nil :: any,
		_stand = nil :: Instance?,
		_connections = {} :: { RBXScriptConnection },
	}, ShopService) :: ServiceTypes.Shop

	PlayerCache[Player] = self
	return self
end

function ShopService:SendDependencies(Deps: { [string]: any }): ()
	self._economy = Deps.Economy
	self._gear = Deps.Gear
end

-- ====================== STAND ======================

function ShopService:AssignStand(Stand: Model | Folder | BasePart): ()
	assert(not self._stand, "Player already has a stand assigned.")
	self._stand = Stand
	self:_SetupPrompt()
end

function ShopService:_SetupPrompt(): ()
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

function ShopService:_OnPromptTriggered(Interactor: Player): ()
	local Economy = self._economy :: any
	local Gear = self._gear :: any

	OpenShopEvent:Server():Fire(Interactor, {
		Owner = self.Player.Name,
		Equipped = Gear:GetEquipped(),
		Inventory = Economy:Get("Inventory"),
		Slots = Economy:Get("Slots"),
	})
end

function ShopService:_TeardownPrompt(): ()
	for _, Connection in self._connections do
		Connection:Disconnect()
	end
	table.clear(self._connections)
	self._stand = nil
end

-- ====================== SHOP ======================

function ShopService:SellEquipped(Price: number): ()
	local Equipped = self._gear:GetEquipped()
	assert(Equipped ~= "", "No gear is currently equipped.")

	self._gear:UnEquipGear(Equipped)
	self._economy:AddCurrency(Price, "Cash")
end

function ShopService:SellInventoryItem(ItemKey: string, Price: number): ()
	local Inventory = self._economy:Get("Inventory")
	assert(Inventory[ItemKey], `Item {ItemKey} not found in inventory.`)

	self._economy:RemoveFromTable("Inventory", ItemKey)
	self._economy:AddCurrency(Price, "Cash")
end

-- ====================== GETTERS ======================

function ShopService.GetByPlayer(Player: Player): ServiceTypes.Shop?
	return PlayerCache[Player]
end

-- ====================== LIFECYCLE ======================

function ShopService:Destroy(): ()
	self:_TeardownPrompt()

	PlayerCache[self.Player] = nil
	self.Player = nil :: any
	self._economy = nil :: any
	self._gear = nil :: any
	setmetatable(self, nil)
end

return ShopService
