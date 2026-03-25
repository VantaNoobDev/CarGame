--!strict
--!native
local ServerScriptService = game:GetService("ServerScriptService")
local ServiceTypes = require(ServerScriptService.Server.Core.Types.ServiceTypes)

-- ====================== BASE SERVICE ======================

local Bases: { [Folder]: boolean } = {}
local PlayerCache: { [Player]: ServiceTypes.Base } = {}

local Allowed = { "Model", "Baseplate", "Spawn" }

local BaseService = {}
BaseService.__index = BaseService

do
	local BasesFolder = workspace:WaitForChild("Map"):WaitForChild("Bases") :: Folder
	for _, Base in BasesFolder:GetChildren() do
		if Base:IsA("Folder") then
			Bases[Base] = false
		else
			error(`Expected Folder in Bases, got {Base.ClassName} ({Base.Name})`)
		end
	end
end

function BaseService.new(Player: Player): ServiceTypes.Base
	local self = setmetatable({
		Player = Player,
		Base = nil,
		_economy = nil :: any,
	}, BaseService) :: ServiceTypes.Base

	PlayerCache[Player] = self
	return self
end

function BaseService:SendDependencies(Deps: { [string]: any }): ()
	self._economy = Deps.Economy
end

-- ====================== HELPERS ======================

local function GetBillboardLabels(Base: Folder): (TextLabel?, ImageLabel?)
	local Info = Base:FindFirstChild("Info") :: Folder?
	if not Info then
		return nil, nil
	end
	local Billboard = Info:FindFirstChild("Billboard") :: Instance?
	if not Billboard then
		return nil, nil
	end
	return Billboard:FindFirstChildOfClass("TextLabel"), Billboard:FindFirstChildOfClass("ImageLabel")
end

-- ====================== BASE ======================

function BaseService:AddToBase(): ()
	assert(not self.Base, "Player already has a base assigned.")

	for Base, Taken in Bases do
		if not Taken then
			Bases[Base] = true
			self.Base = Base

			local Name, Thumbnail = GetBillboardLabels(Base)
			if Name and Thumbnail then
				Name.Text = self.Player.Name
				Thumbnail.Image = `rbxthumb://type=AvatarHeadShot&id={self.Player.UserId}&w=420&h=420`
			end

			-- TODO: populate stands from self._economy:Get("Slots")

			break
		end
	end

	assert(self.Base, "No available bases found.")
end

function BaseService:RemoveFromBase(): ()
	assert(self.Base, "Player has no base but tried to remove it.")

	local Base: Folder = self.Base
	Bases[Base] = false

	local Name, Thumbnail = GetBillboardLabels(Base)
	if Name then
		Name.Text = ""
	end
	if Thumbnail then
		Thumbnail.Image = ""
	end

	local Stands = Base:FindFirstChild("Stands") :: Folder?
	if Stands then
		for _, Stand in Stands:GetChildren() do
			for _, Model in Stand:GetChildren() do
				if not table.find(Allowed, Model.Name) then
					Model:Destroy()
				end
			end
		end
	end

	self.Base = nil
end

-- ====================== GETTERS ======================

function BaseService.GetByPlayer(Player: Player): ServiceTypes.Base?
	return PlayerCache[Player]
end

-- ====================== LIFECYCLE ======================

function BaseService:Destroy(): ()
	if self.Base then
		self:RemoveFromBase()
	end

	PlayerCache[self.Player] = nil
	self.Player = nil :: any
	self.Base = nil :: any
	setmetatable(self, nil)
end

return BaseService
