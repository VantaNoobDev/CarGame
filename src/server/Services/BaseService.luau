--!strict
--!native
local ServerScriptService = game:GetService("ServerScriptService")
local EconomyService = require(script.Parent.EconomyService)
local ServiceTypes = require(ServerScriptService.Server.Core.Types.ServiceTypes)

local Bases: { [Folder]: boolean } = {}
local PlayerCache: { [Player]: ServiceTypes.Base } = {}

local Allowed = { "Model", "Baseplate", "Spawn" }

local BaseService = {}
BaseService.__index = BaseService

do
	local BasesFolder = workspace:WaitForChild("Map"):WaitForChild("Bases") :: Folder
	for _, Base in pairs(BasesFolder:GetChildren()) do
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
	}, BaseService) :: ServiceTypes.Base

	PlayerCache[Player] = self
	return self
end

function BaseService:AddToBase(): ()
	assert(not self.Base, "Player already has a base assigned.")

	for Base, Taken in pairs(Bases) do
		if not Taken then
			Bases[Base] = true
			self.Base = Base

			local Billboard = Base:WaitForChild("Info"):WaitForChild("Billboard")
			local Name = Billboard:FindFirstChildOfClass("TextLabel")
			local Thumbnail = Billboard:FindFirstChildOfClass("ImageLabel")

			if Name and Thumbnail then
				Name.Text = self.Player.Name
				Thumbnail.Image = `rbxthumb://type=AvatarHeadShot&id={self.Player.UserId}&w=420&h=420`
			end

			-- TODO: populate stands from EconomyService:GetPlayerData(self.Player) Slots data

			break
		end
	end
end

function BaseService:RemoveFromBase(): ()
	assert(self.Base, "Player has no base but tried to remove it.")

	local Base: Folder = self.Base
	Bases[Base] = false

	local Billboard = Base:FindFirstChild("Info") and Base:WaitForChild("Info"):FindFirstChild("Billboard")
	if Billboard then
		local Name = Billboard:FindFirstChildOfClass("TextLabel")
		local Thumbnail = Billboard:FindFirstChildOfClass("ImageLabel")

		if Name then
			Name.Text = ""
		end
		if Thumbnail then
			Thumbnail.Image = ""
		end
	end

	local Stands = Base:FindFirstChild("Stands")
	if Stands then
		for _, Stand in pairs(Stands:GetChildren()) do
			for _, Model in pairs(Stand:GetChildren()) do
				if not table.find(Allowed, Model.Name) then
					Model:Destroy()
				end
			end
		end
	end

	self.Base = nil
end

function BaseService:GetPlayerData(Player: Player): ServiceTypes.Base?
	return PlayerCache[Player]
end

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
