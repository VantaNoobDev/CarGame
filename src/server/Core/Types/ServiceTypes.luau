--!strict
export type Economy = {
	new: (Player: Player) -> Economy,
	AddCurrency: (self: Economy, Amount: number, Value: EconomyData) -> (),
	RemoveCurrency: (self: Economy, Amount: number, Value: EconomyData) -> (),
	ResetCurrency: (self: Economy, Value: EconomyData) -> (),
	AddTable: (self: Economy, InfoToBeChanged: string, InfoToBeAdded: string, Value: EconomyData) -> (),
	RemoveTable: (self: Economy, InfoToBeChanged: EconomyData, InfoToBeRemoved: string, Value: EconomyData) -> (),
	ResetTable: (self: Economy, InfoToBeChanged: EconomyData) -> (),
	Get: (self: Economy, Value: EconomyData) -> number | string | { any? },
	GetPlayerData: (self: Economy, Player: Player) -> Economy?,
	Destroy: (self: Economy) -> (),
}

export type Gear = {
	EquippedItem: string,
	_connections: { RBXScriptConnection },

	new: (Player: Player) -> Gear,
	EquipGear: (
		self: Gear,
		GearType: GearData,
		Name: string,
		ToolTip: string,
		Model: Model | Folder,
		GearId: number
	) -> (),
	UnEquipGear: (self: Gear, GearId: number) -> (),
	Get: (self: Gear) -> string,
	GetPlayerData: (self: Gear, Player: Player) -> Gear?,
	Destroy: (self: Gear) -> (),
}

export type Base = {
	Player: Player,
	Base: Folder?,

	new: (Player: Player) -> Base,
	AddToBase: (self: Base) -> (),
	RemoveFromBase: (self: Base) -> (),
	GetPlayerData: (self: Base, Player: Player) -> Base?,
	Destroy: (self: Base) -> (),
}

export type EconomyData = "Inventory" | "Index" | "Slots" | "RobloxInventory" | "Cash"
export type GearData = "Usable" | "ItemForBase"
export type BaseData = "Taken" | "UnTaken"

return {}
