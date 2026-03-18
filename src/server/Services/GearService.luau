--!strict
--!native
local ServerScriptService = game:GetService("ServerScriptService")
local ServiceTypes = require(ServerScriptService.Server.Core.Types.ServiceTypes)

local GearService = {}
GearService.__index = GearService

function GearService.new(Player: Player): ServiceTypes.Gear
	return setmetatable({
		Player = Player,
		EquippedItem = "",
	}, GearService) :: any
end

function GearService:EquipGear(
	GearType: ServiceTypes.GearData,
	Name: string,
	ToolTip: string,
	Model: Model | Folder,
	GearId: number
): ()
	local Backpack = self.Player:FindFirstChild("Backpack") :: Folder
	local StarterGear = self.Player:FindFirstChild("StarterGear") :: Folder

	assert(Backpack, "Backpack not found, player is probably not loaded yet.")
	assert(StarterGear, "StarterGear not found, player is probably not loaded yet.")

	local NewTool = Instance.new("Tool")
	NewTool.ToolTip = ToolTip
	NewTool.Name = Name

	Model:Clone().Parent = NewTool

	local Handle = Instance.new("Part")
	Handle.Name = "Handle"
	Handle.Parent = NewTool

	if Model:IsA("Model") then
		assert(Model.PrimaryPart, "Primary part not found in model.")

		Handle.Position = Model.PrimaryPart.Position
		Handle.Size = Model.PrimaryPart.Size
	end

	NewTool.Parent = Backpack

	local ToolClone = NewTool:Clone()
	ToolClone.Parent = StarterGear

	NewTool:SetAttribute("GearId", GearId)
	ToolClone:SetAttribute("GearId", GearId)

	NewTool.Equipped:Connect(function()
		self.EquippedItem = Name
	end)

	ToolClone.Equipped:Connect(function()
		self.EquippedItem = Name
	end)

	NewTool.Unequipped:Connect(function()
		self.EquippedItem = ""
	end)

	ToolClone.Unequipped:Connect(function()
		self.EquippedItem = ""
	end)
end

function GearService:UnEquipGear(GearId: number)
	local Backpack = self.Player:FindFirstChild("Backpack") :: Folder
	local StarterGear = self.Player:FindFirstChild("StarterGear") :: Folder

	assert(Backpack, "Backpack not found, player is probably not loaded yet.")
	assert(StarterGear, "StarterGear not found, player is probably not loaded yet.")

	for _, Tool in pairs(Backpack:GetChildren()) do
		if Tool:GetAttribute("GearId") and Tool:GetAttribute("GearId") == GearId then
			Tool:Destroy()
		end
	end
	for _, Tool in pairs(StarterGear:GetChildren()) do
		if Tool:GetAttribute("GearId") and Tool:GetAttribute("GearId") == GearId then
			Tool:Destroy()
		end
	end
end

function GearService:Get()
	return self.EquippedItem
end

return GearService
