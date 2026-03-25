-- Framework.lua
--!strict
-- Public Framework for this template
-- Fully automatic wrappers + automatic dependency injection

local Players = game:GetService("Players")

-- ====================== SERVICE REGISTRY ======================

local Loader = require(script.Parent.Parent.Loader.Loader)
local Services = Loader.Load(script.Parent.Parent.Services)
local Types = require(script.Parent.Parent.Core.Types.ServiceTypes)

local EconomyService = Services.EconomyService :: Types.Economy
local GearService = Services.GearService :: Types.Gear
local BaseService = Services.BaseService :: Types.Base
local SellingService = Services.SellingService :: Types.Selling
local ShopService = Services.ShopService :: Types.Shop
local StealingService = Services.StealingService :: Types.Stealing
local SpawningService = Services.SpawningService :: Types.Spawning

type ServiceExample = {
	new: (Player: Player) -> (),
}

local ServiceClasses = {
	Economy = EconomyService,
	Gear = GearService,
	Base = BaseService,
	Selling = SellingService,
	Shop = ShopService,
	Stealing = StealingService,
	Spawning = SpawningService,
}

local ServiceDependencies: { [string]: { string } } = {
	Economy = {},
	Gear = { "Economy", "Base" },
	Base = { "Economy" },
	Selling = { "Economy", "Gear" },
	Shop = { "Economy", "Gear" },
	Stealing = { "Economy", "Gear" },
	Spawning = { "Economy", "Gear" },
}

-- ====================== INTERNAL STATE ======================

local PlayerServices: { [Player]: { [string]: any } } = {}

-- ====================== PLAYER JOIN / LEAVE ======================

local function OnPlayerAdded(Player: Player)
	local ServiceInstances: { [string]: any } = {}
	for ServiceName, Class in pairs(ServiceClasses) do
		local TypedClass = Class :: ServiceExample
		local NewFn = TypedClass.new
		if NewFn and typeof(NewFn) == "function" then
			ServiceInstances[ServiceName :: string] = TypedClass.new(Player)
		end
	end

	for ServiceName, Deps in pairs(ServiceDependencies) do
		local Service = ServiceInstances[ServiceName]
		if Service.SendDependencies and typeof(Service.SendDependencies) == "function" then
			local DepInstances: { [string]: any } = {}
			for _, DepName in ipairs(Deps) do
				DepInstances[DepName] = ServiceInstances[DepName]
			end
			(Service.SendDependencies :: (any, { [string]: any }) -> ())(Service, DepInstances)
		end
	end

	PlayerServices[Player] = ServiceInstances
end

local function OnPlayerRemoving(Player: Player)
	local Services = PlayerServices[Player]
	if Services then
		for _, Service in pairs(Services) do
			if Service and typeof(Service.Destroy) == "function" then
				pcall(Service.Destroy :: (any) -> (), Service)
			end
		end
		PlayerServices[Player] = nil
	end
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

-- ====================== WRAPPERS ======================

local Framework: { [string]: any } = {}

for ServiceName, _ in pairs(ServiceClasses) do
	Framework[ServiceName] = setmetatable({}, {
		__index = function(_, MethodName: string)
			return function(FirstArg, ...: any)
				local TargetPlayer: Player
				local Args: { any } = { ... }

				if typeof(FirstArg) == "Instance" and FirstArg:IsA("Player") then
					TargetPlayer = FirstArg
				else
					TargetPlayer = Args[1]
					table.remove(Args, 1)
				end

				local PlayerServiceMap = PlayerServices[TargetPlayer]
				assert(
					PlayerServiceMap and PlayerServiceMap[ServiceName],
					`No {ServiceName} service found for {TargetPlayer.Name}`
				)

				local Method = PlayerServiceMap[ServiceName][MethodName]
				assert(Method, `Method {MethodName} does not exist on {ServiceName} service`)

				return (Method :: (any, ...any) -> ...any)(PlayerServiceMap[ServiceName], table.unpack(Args))
			end
		end,
	})
end

return setmetatable(Framework, {
	__newindex = function()
		error("Framework is read-only")
	end,
})
