--!strict
--!native
local ServerScriptService = game:GetService("ServerScriptService")
local ServiceTypes = require(ServerScriptService.Server.Core.Types.ServiceTypes)

-- ====================== GEAR SERVICE ======================

local GearService = {}
GearService.__index = GearService

local PlayerCache: { [Player]: ServiceTypes.Gear } = {}

function GearService.new(Player: Player): ServiceTypes.Gear
	local self = setmetatable({
		Player = Player,
		EquippedItem = "",
		_connections = {} :: { RBXScriptConnection },
		_economy = nil :: any,
	}, GearService) :: ServiceTypes.Gear

	PlayerCache[Player] = self
	return self
end

function GearService:SendDependencies(Deps: { [string]: any }): ()
	self._economy = Deps.Economy
	self._base = Deps.Base
end

-- ====================== GEAR ======================

local function GetPlayerContainers(Player: Player): (Folder, Folder)
	local Backpack = Player:FindFirstChild("Backpack") :: Folder
	local StarterGear = Player:FindFirstChild("StarterGear") :: Folder
	assert(Backpack, "Backpack not found, player is probably not loaded yet.")
	assert(StarterGear, "StarterGear not found, player is probably not loaded yet.")
	return Backpack, StarterGear
end

function GearService:EquipGear(
	GearType: ServiceTypes.GearData,
	Name: string,
	ToolTip: string,
	Model: Model | Folder,
	GearId: number
): ()
	local Backpack, StarterGear = GetPlayerContainers(self.Player)

	local NewTool = Instance.new("Tool")
	NewTool.ToolTip = ToolTip
	NewTool.Name = Name
	NewTool:SetAttribute("GearId", GearId)

	local Handle = Instance.new("Part")
	Handle.Name = "Handle"

	if Model:IsA("Model") then
		assert(Model.PrimaryPart, "Primary part not found in model.")
		Handle.Position = Model.PrimaryPart.Position
		Handle.Size = Model.PrimaryPart.Size
	else
		local FirstPart = Model:FindFirstChildWhichIsA("BasePart")
		if FirstPart then
			Handle.Position = FirstPart.Position
			Handle.Size = FirstPart.Size
		end
	end

	Handle.Parent = NewTool
	Model:Clone().Parent = NewTool

	table.insert(
		self._connections,
		NewTool.Equipped:Connect(function()
			self.EquippedItem = Name
		end)
	)

	table.insert(
		self._connections,
		NewTool.Unequipped:Connect(function()
			self.EquippedItem = ""
		end)
	)

	NewTool.Parent = Backpack
	NewTool:Clone().Parent = StarterGear
end

function GearService:UnEquipGear(GearId: number): ()
	local Backpack, StarterGear = GetPlayerContainers(self.Player)

	for _, Tool in Backpack:GetChildren() do
		if Tool:GetAttribute("GearId") == GearId then
			Tool:Destroy()
		end
	end

	for _, Tool in StarterGear:GetChildren() do
		if Tool:GetAttribute("GearId") == GearId then
			Tool:Destroy()
		end
	end
end

-- ====================== GETTERS ======================

function GearService:GetEquipped(): string
	return self.EquippedItem
end

function GearService.GetByPlayer(Player: Player): ServiceTypes.Gear?
	return PlayerCache[Player]
end

-- ====================== LIFECYCLE ======================

function GearService:Destroy(): ()
	for _, Connection in self._connections :: any do
		Connection:Disconnect()
	end

	PlayerCache[self.Player] = nil
	self.Player = nil :: any
	self._connections = nil :: any
	setmetatable(self, nil)
end

return GearService
