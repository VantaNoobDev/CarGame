--!strict
--!native
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local ServiceTypes = require(ServerScriptService.Server.Core.Types.ServiceTypes)

-- ====================== CONSTANTS ======================

local NIL_MODEL = Instance.new("Model")
local RESPAWN_INTERVAL = 60 -- seconds before a stand respawns if untouched
local CHECK_INTERVAL = 5 -- how often to poll stands in seconds

-- ====================== SAFE ZONE ======================

-- TODO: replace with actual safe zone part reference
local SafeZonePart = workspace:WaitForChild("Map"):WaitForChild("SafeZone") :: BasePart

local function IsInSafeZone(Player: Player): boolean
	local Character = Player.Character
	if not Character then
		return false
	end
	local RootPart = Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not RootPart then
		return false
	end

	local Parts = workspace:GetPartBoundsInBox(SafeZonePart.CFrame, SafeZonePart.Size)
	for _, Part in Parts do
		if Part:IsDescendantOf(Character) then
			return true
		end
	end
	return false
end

-- ====================== STAND REGISTRY (SINGLETON) ======================

type StandData = {
	Slot: Instance,
	StealBase: Instance,
	LastSpawnTime: number,
	HasItem: boolean,
}

local Stands: { [number]: StandData } = {}
local NextStandId = 1

local function RegisterStands(): ()
	local Map = workspace:WaitForChild("Map") :: Folder
	local BasesFolder = Map:WaitForChild("StealBases") :: Folder?
	if not BasesFolder then
		return
	end

	for _, Base in BasesFolder:GetChildren() do
		for _, Slot in Base:GetChildren() do
			local Spawn = Slot:FindFirstChild("Spawn")
			if not Spawn then
				continue
			end

			local Id = NextStandId
			NextStandId += 1

			-- Tag the slot with its ID so StealingService can reference it
			Slot:SetAttribute("StandId", Id)

			Stands[Id] = {
				Slot = Slot,
				StealBase = Base,
				LastSpawnTime = 0,
				HasItem = false,
			}
		end
	end
end

local function SpawnItemOnStand(Stand: StandData): ()
	-- TODO: load actual item model from definitions
	local Item = Instance.new("Model")
	Item.Name = "StolenItem" -- TODO: pick from item definitions
	Item.Parent = Stand.Slot

	Stand.HasItem = true
	Stand.LastSpawnTime = os.clock()
end

local function StartStandLoop(): ()
	local Elapsed = 0
	RunService.Heartbeat:Connect(function(Delta: number)
		Elapsed += Delta
		if Elapsed < CHECK_INTERVAL then
			return
		end
		Elapsed = 0

		local Now = os.clock()
		for _, Stand in Stands do
			local IsEmpty = not Stand.HasItem
			local IsStale = (Now - Stand.LastSpawnTime) >= RESPAWN_INTERVAL

			if IsEmpty or IsStale then
				-- Clear old item if stale but not taken
				if IsStale and not IsEmpty then
					for _, Child in Stand.Slot:GetChildren() do
						if Child:IsA("Model") then
							Child:Destroy()
						end
					end
					Stand.HasItem = false
				end

				SpawnItemOnStand(Stand)
			end
		end
	end)
end

-- Called by StealingService when an item is stolen
local function OnItemStolen(StandId: number): ()
	local Stand = Stands[StandId]
	if not Stand then
		return
	end
	Stand.HasItem = false
	Stand.LastSpawnTime = os.clock()
end

-- ====================== SPAWNING SERVICE (PER-PLAYER) ======================

local SpawningService = {}
SpawningService.__index = SpawningService

local PlayerCache: { [Player]: ServiceTypes.Spawning } = {}

-- Initialize stand registry once at module load
RegisterStands()
StartStandLoop()

-- ====================== MONSTER ======================

local function SpawnMonster(_StealBase: Instance): Model
	-- TODO: load actual monster model + position at steal base
	local Monster = Instance.new("Model")
	Monster.Name = "Monster"
	Monster.Parent = workspace
	return Monster
end

local function DespawnMonster(Monster: Model): ()
	Monster:Destroy()
end

function SpawningService:SendDependencies(Deps: { [string]: any }): ()
	self._economy = Deps.Economy
	self._gear = Deps.Gear
end

-- ====================== CHASE ======================

function SpawningService.new(Player: Player): ServiceTypes.Spawning
	local self = setmetatable({
		Player = Player,
		_monster = nil :: Model?,
		_stealBase = nil :: Instance?,
		_stolenItem = nil :: Instance?,
		_standId = nil :: number?,
		_itemKey = nil :: string?,
		_isChasing = false,
		_connections = {} :: { RBXScriptConnection },
		_economy = nil :: any,
		_gear = nil :: any,
	}, SpawningService) :: ServiceTypes.Spawning

	PlayerCache[Player] = self
	return self
end

function SpawningService:StartChase(StealBase: Instance, StolenItem: Instance, StandId: number, ItemKey: string): ()
	assert(not self._isChasing, "Player is already being chased.")

	self._stealBase = StealBase
	self._stolenItem = StolenItem
	self._standId = StandId
	self._itemKey = ItemKey
	self._isChasing = true
	self._monster = SpawnMonster(StealBase)

	OnItemStolen(StandId)

	table.insert(
		self._connections,
		RunService.Heartbeat:Connect(function()
			if not self._isChasing then
				return
			end

			if IsInSafeZone(self.Player) then
				self:_OnPlayerEscaped()
				return
			end

			-- TODO: monster pathfinding toward self.Player
			-- TODO: check monster touched player → self:_OnPlayerCaught()
		end)
	)
end

function SpawningService:_OnPlayerEscaped(): ()
	self._isChasing = false

	-- Player escaped — award item to inventory
	local Economy = self._economy :: any
	if Economy and self._itemKey then
		Economy:AddToTable("Inventory", self._itemKey)
	end

	if self._monster then
		DespawnMonster(self._monster)
		self._monster = NIL_MODEL
	end

	self._stealBase = nil
	self._stolenItem = nil
	self._standId = nil
	self._itemKey = nil
	self:_ClearConnections()
end

function SpawningService:_OnPlayerCaught(): ()
	self._isChasing = false

	-- Player caught — return item to stand, don't award inventory
	if self._stolenItem and self._stealBase and self._standId then
		self._stolenItem.Parent = Stands[self._standId].Slot
		Stands[self._standId].HasItem = true
		Stands[self._standId].LastSpawnTime = os.clock()
		self._stolenItem = NIL_MODEL
	end

	local Gear = self._gear :: any
	if Gear then
		local Equipped: string = Gear:GetEquipped()
		if Equipped ~= "" then
			Gear:UnEquipGear(Equipped)
		end
	end

	-- TODO: ragdoll player back to safe area

	if self._monster then
		DespawnMonster(self._monster)
		self._monster = NIL_MODEL
	end

	self._stealBase = nil
	self._standId = nil
	self._itemKey = nil
	self:_ClearConnections()
end

function SpawningService:_ClearConnections(): ()
	for _, Connection in self._connections do
		Connection:Disconnect()
	end
	table.clear(self._connections)
end

-- ====================== GETTERS ======================

function SpawningService:IsChasing(): boolean
	return self._isChasing
end

function SpawningService.GetByPlayer(Player: Player): ServiceTypes.Spawning?
	return PlayerCache[Player]
end

function SpawningService.GetStand(StandId: number): StandData?
	return Stands[StandId]
end

-- ====================== LIFECYCLE ======================

function SpawningService:Destroy(): ()
	if self._isChasing then
		self:_OnPlayerEscaped()
	end

	self:_ClearConnections()

	PlayerCache[self.Player] = nil
	self.Player = nil :: any
	self._economy = nil :: any
	self._gear = nil :: any
	setmetatable(self, nil)
end

return SpawningService
