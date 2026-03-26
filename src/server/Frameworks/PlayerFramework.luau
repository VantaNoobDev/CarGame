-- Framework.lua
--!strict
--!native

local Players = game:GetService("Players")
local Loader = require(script.Parent.Parent.Loader.Loader)
local Services = Loader.Load(script.Parent.Parent.Services)
local Types = require(script.Parent.Parent.Core.Types.ServiceTypes)

-- ====================== TYPES ======================

type Destroyable = {
	Destroy: (self: Destroyable) -> (),
}

type PlayerServiceMap = {
	Economy: Types.Economy?,
	Gear: Types.Gear?,
	Base: Types.Base?,
	Selling: Types.Selling?,
	Shop: Types.Shop?,
	Stealing: Types.Stealing?,
	Spawning: Types.Spawning?,
	Destroy: (self: PlayerServiceMap) -> (),
}

type ServiceClass<T> = {
	new: (Player: Player) -> T,
}

type MethodForward<T> = {
	[T]: (Player: Player, ...any) -> ...any,
}

-- ====================== SERVICE REGISTRY ======================

local ServiceClasses: { [string]: ServiceClass<any> } = {
	Economy = Services.EconomyService :: ServiceClass<Types.Economy>,
	Gear = Services.GearService :: ServiceClass<Types.Gear>,
	Base = Services.BaseService :: ServiceClass<Types.Base>,
	Selling = Services.SellingService :: ServiceClass<Types.Selling>,
	Shop = Services.ShopService :: ServiceClass<Types.Shop>,
	Stealing = Services.StealingService :: ServiceClass<Types.Stealing>,
	Spawning = Services.SpawningService :: ServiceClass<Types.Spawning>,
}

local ServiceDependencies: { [string]: { string } } = {
	Economy = {},
	Base = { "Economy" },
	Gear = { "Economy", "Base" },
	Selling = { "Economy", "Gear" },
	Shop = { "Economy", "Gear" },
	Stealing = { "Economy", "Gear" },
	Spawning = { "Economy", "Gear" },
}

-- ====================== LOAD ORDER ======================

local function ResolveLoadOrder(
	Classes: { [string]: ServiceClass<any> },
	Dependencies: { [string]: { string } }
): { string }
	local Order = {}
	local Done = {}
	local InStack = {}

	local function LoadService(ServiceName: string)
		if Done[ServiceName] then
			return
		end
		if InStack[ServiceName] then
			error("Framework: Circular dependency detected involving service '" .. ServiceName .. "'.")
		end
		InStack[ServiceName] = true
		for _, DepName in ipairs(Dependencies[ServiceName] or {}) do
			assert(Classes[DepName], "Unknown dependency '" .. DepName .. "' for service '" .. ServiceName .. "'.")
			LoadService(DepName)
		end
		InStack[ServiceName] = nil
		Done[ServiceName] = true
		table.insert(Order, ServiceName)
	end

	for Name in pairs(Classes) do
		LoadService(Name)
	end

	return Order
end

local LoadOrder = ResolveLoadOrder(ServiceClasses, ServiceDependencies)

-- ====================== PLAYER SERVICE STORAGE ======================

local PlayerServices: { [Player]: PlayerServiceMap } = setmetatable({}, { __mode = "k" }) :: { [Player]: PlayerServiceMap }
local PlayerLoadEvents: { [Player]: { [string]: BindableEvent } } = {}

-- ====================== CREATE & DESTROY ======================

local function CreateServices(Player: Player): PlayerServiceMap
	local Instances: { [string]: any } = {}

	for _, ServiceName in ipairs(LoadOrder) do
		local Class = ServiceClasses[ServiceName]
		assert(Class and Class.new, "Service '" .. ServiceName .. "' missing .new() constructor.")
		local OK, Result = pcall(Class.new, Player)
		if OK and Result then
			Instances[ServiceName] = Result
		else
			error(
				"Failed to construct service '"
					.. ServiceName
					.. "' for "
					.. Player.Name
					.. ". Error: "
					.. tostring(Result)
			)
		end
	end

	for ServiceName, Deps in pairs(ServiceDependencies) do
		local Service = Instances[ServiceName]
		if Service and typeof(Service.SendDependencies) == "function" then
			local Injected: { [string]: any } = {}
			for _, DepName in ipairs(Deps) do
				local Dep = Instances[DepName]
				if Dep then
					Injected[DepName] = Dep
				else
					warn(
						"Dependency '" .. DepName .. "' missing for service '" .. ServiceName .. "' for " .. Player.Name
					)
				end
			end
			local OK, Err = pcall(Service.SendDependencies :: any, Service, Injected)
			if not OK then
				warn("SendDependencies failed for '" .. ServiceName .. "'. Error: " .. tostring(Err))
			end
		end
	end

	local function Destroy(self: PlayerServiceMap)
		for i = #LoadOrder, 1, -1 do
			local Name = LoadOrder[i]
			local S = (self :: any)[Name]
			if S and typeof(S.Destroy) == "function" then
				local OK, Err = pcall(S.Destroy :: any, S)
				if not OK then
					warn("Destroy failed for '" .. Name .. "'. Error: " .. tostring(Err))
				end
			end
		end
	end
	Instances.Destroy = Destroy

	if PlayerLoadEvents[Player] then
		for _, Event in pairs(PlayerLoadEvents[Player]) do
			Event:Fire()
			Event:Destroy()
		end
		PlayerLoadEvents[Player] = nil
	end

	return Instances :: PlayerServiceMap
end

local function DestroyServices(Map: PlayerServiceMap)
	if Map and Map.Destroy then
		Map:Destroy()
	end
end

-- ====================== PLAYER EVENTS ======================

local function OnPlayerAdded(Player: Player)
	task.defer(function()
		PlayerLoadEvents[Player] = {}
		local Map = CreateServices(Player)
		PlayerServices[Player] = Map
	end)
end

local function OnPlayerRemoving(Player: Player)
	local Map = PlayerServices[Player]
	if Map then
		DestroyServices(Map)
		PlayerServices[Player] = nil
	end

	if PlayerLoadEvents[Player] then
		for _, Event in pairs(PlayerLoadEvents[Player]) do
			Event:Destroy()
		end
		PlayerLoadEvents[Player] = nil
	end
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

for _, P in ipairs(Players:GetPlayers()) do
	task.defer(OnPlayerAdded, P)
end

-- ====================== FULLY TYPED API ======================

local Framework = {}

local function WaitForService<PlayerServiceName, PlayerServiceMap>(Player: Player, ServiceName: PlayerServiceName): PlayerServiceMap
	if PlayerServices[Player] and (PlayerServices[Player] :: any)[ServiceName] then
		return (PlayerServices[Player] :: any)[ServiceName]
	end

	PlayerLoadEvents[Player] = PlayerLoadEvents[Player] or {}
	if not PlayerLoadEvents[Player][ServiceName] then
		PlayerLoadEvents[Player][ServiceName] = Instance.new("BindableEvent")
	end

	PlayerLoadEvents[Player][ServiceName].Event:Wait()
	return (PlayerServices[Player] :: any)[ServiceName]
end

local function GetService<T>(Player: Player, ServiceName: string): T
	if not PlayerServices[Player] or not (PlayerServices[Player] :: any)[ServiceName] then
		return WaitForService(Player, ServiceName) :: T
	end
	return (PlayerServices[Player] :: any)[ServiceName] :: T
end

-- Fully typed MakeAPI
local function MakeTypedAPI<ServiceName, PlayerServiceMap>(Name: ServiceName): MethodForward<PlayerServiceMap>
	local API: MethodForward<PlayerServiceMap> = {}

	local Class = ServiceClasses[Name]
	assert(Class and Class.new, "Service '" .. Name :: string .. "' missing .new() constructor.")

	local DummyPlayer = {} :: Player | any
	local TempInstance = Class.new(DummyPlayer)

	for MethodName, MethodValue in pairs(TempInstance) do
		if typeof(MethodValue) == "function" then
			API[MethodName] = function(Player: Player, ...: any)
				local Service = GetService(Player, Name)
				local M = (Service :: any)[MethodName] :: (any, ...any) -> ...any
				assert(
					typeof(M) == "function",
					"Method '" .. MethodName :: string .. "' missing on service '" .. Name :: string .. "'"
				)
				return M(Service, ...)
			end
		end
	end

	return API
end

Framework.Economy = MakeTypedAPI("Economy")
Framework.Gear = MakeTypedAPI("Gear")
Framework.Base = MakeTypedAPI("Base")
Framework.Selling = MakeTypedAPI("Selling")
Framework.Shop = MakeTypedAPI("Shop")
Framework.Stealing = MakeTypedAPI("Stealing")
Framework.Spawning = MakeTypedAPI("Spawning")

function Framework.DestroyPlayerServices(Player: Player)
	local Map = PlayerServices[Player]
	if Map then
		DestroyServices(Map)
		PlayerServices[Player] = nil
	end
end

return table.freeze(Framework)
