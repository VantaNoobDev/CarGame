-- ServiceTypes.lua
--!strict
-- Types for Framework services
-- Provides full type safety and autocomplete for Economy, Gear, Base, Selling, and Stealing

-- =========================
-- ECONOMY TYPES
-- =========================

export type EconomyData = "Inventory" | "Index" | "Slots" | "RobloxInventory" | "Cash"

export type Economy = {
	Player: Player,

	new: (Player: Player) -> Economy,
	SendDependencies: (self: Economy, Deps: { [string]: any }) -> (),

	AddCurrency: (self: Economy, Amount: number, Key: EconomyData) -> (),
	RemoveCurrency: (self: Economy, Amount: number, Key: EconomyData) -> (),
	SetCurrency: (self: Economy, Amount: number, Key: EconomyData) -> (),
	ResetCurrency: (self: Economy, Key: EconomyData) -> (),

	AddToTable: (self: Economy, TableKey: string, EntryKey: string) -> (),
	RemoveFromTable: (self: Economy, TableKey: string, EntryKey: string) -> (),
	ClearTable: (self: Economy, TableKey: string) -> (),

	Get: (self: Economy, Key: EconomyData) -> number | string | { any? },
	GetByPlayer: (Player: Player) -> Economy?,

	Destroy: (self: Economy) -> (),
}

-- =========================
-- GEAR TYPES
-- =========================

export type GearData = "Usable" | "ItemForBase"

export type Gear = {
	Player: Player,
	EquippedItem: string,
	_connections: { RBXScriptConnection },

	new: (Player: Player) -> Gear,
	SendDependencies: (self: Gear, Deps: { [string]: any }) -> (),

	EquipGear: (
		self: Gear,
		GearType: GearData,
		Name: string,
		ToolTip: string,
		Model: Model | Folder,
		GearId: number
	) -> (),
	UnEquipGear: (self: Gear, GearId: number) -> (),

	GetEquipped: (self: Gear) -> string,
	GetByPlayer: (Player: Player) -> Gear?,

	Destroy: (self: Gear) -> (),
}

-- =========================
-- BASE TYPES
-- =========================

export type BaseData = "Taken" | "UnTaken"

export type Base = {
	Player: Player,
	Base: Folder?,

	new: (Player: Player) -> Base,
	SendDependencies: (self: Base, Deps: { [string]: any }) -> (),

	AddToBase: (self: Base) -> (),
	RemoveFromBase: (self: Base) -> (),

	GetByPlayer: (Player: Player) -> Base?,

	Destroy: (self: Base) -> (),
}

-- =========================
-- SELLING TYPES
-- =========================

export type Selling = {
	Player: Player,
	_economy: any,
	_gear: any,
	_stand: Instance?,
	_connections: { RBXScriptConnection },

	new: (Player: Player) -> Selling,
	SendDependencies: (self: Selling, Deps: { [string]: any }) -> (),

	AssignStand: (self: Selling, Stand: Model | Folder | BasePart) -> (),
	_SetupPrompt: (self: Selling) -> (),
	_TeardownPrompt: (self: Selling) -> (),
	_OnPromptTriggered: (self: Selling, Interactor: Player) -> (),

	_SellEquipped: (self: Selling) -> (),
	_SellInventory: (self: Selling) -> (),

	GetByPlayer: (Player: Player) -> Selling?,

	Destroy: (self: Selling) -> (),
}

-- =========================
-- STEALING TYPES
-- =========================

export type Stealing = {
	Player: Player,
	_economy: any,
	_gear: any,
	_connections: { RBXScriptConnection },

	new: (Player: Player) -> Stealing,
	SendDependencies: (self: Stealing, Deps: { [string]: any }) -> (),

	Init: (self: Stealing) -> (),
	_OnSteal: (self: Stealing, Interactor: Player, Slot: Instance) -> (),

	GetByPlayer: (Player: Player) -> Stealing?,

	Destroy: (self: Stealing) -> (),
}

-- =========================
-- SPAWNING TYPES
-- =========================

export type StandData = {
	Slot: Instance,
	StealBase: Instance,
	LastSpawnTime: number,
	HasItem: boolean,
}

export type Spawning = {
	Player: Player,
	_monster: Model?,
	_stealBase: Instance?,
	_stolenItem: Instance?,
	_standId: number?,
	_isChasing: boolean,
	_connections: { RBXScriptConnection },
	_economy: any,
	_gear: any,

	new: (Player: Player) -> Spawning,
	SendDependencies: (self: Spawning, Deps: { [string]: any }) -> (),

	StartChase: (self: Spawning, StealBase: Instance, StolenItem: Instance, StandId: number) -> (),
	_OnPlayerEscaped: (self: Spawning) -> (),
	_OnPlayerCaught: (self: Spawning) -> (),
	_ClearConnections: (self: Spawning) -> (),

	IsChasing: (self: Spawning) -> boolean,
	GetByPlayer: (Player: Player) -> Spawning?,
	GetStand: (StandId: number) -> StandData?,

	Destroy: (self: Spawning) -> (),
}

-- =========================
-- SHOP TYPES
-- =========================

export type Shop = {
	Player: Player,
	_economy: any,
	_gear: any,
	_stand: Instance?,
	_connections: { RBXScriptConnection },

	new: (Player: Player) -> Shop,
	SendDependencies: (self: Shop, Deps: { [string]: any }) -> (),

	AssignStand: (self: Shop, Stand: Model | Folder | BasePart) -> (),
	_SetupPrompt: (self: Shop) -> (),
	_TeardownPrompt: (self: Shop) -> (),
	_OnPromptTriggered: (self: Shop, Interactor: Player) -> (),

	SellEquipped: (self: Shop, Price: number) -> (),
	SellInventoryItem: (self: Shop, ItemKey: string, Price: number) -> (),

	GetByPlayer: (Player: Player) -> Shop?,

	Destroy: (self: Shop) -> (),
}

return {}
