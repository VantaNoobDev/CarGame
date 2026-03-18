--!strict
--!native
export type Economy = {
	new: (Player: Player) -> Economy,
	AddCurrency: (self: Economy, Amount: number, Value: string) -> (),
	RemoveCurrency: (self: Economy, Amount: number, Value: string) -> (),
	ResetCurrency: (self: Economy, Value: string) -> (),
	AddTable: (self: Economy, InfoToBeChanged: string, InfoToBeAdded: string, Value: string) -> (),
	RemoveTable: (self: Economy, InfoToBeChanged: string, InfoToBeAdded: string, Value: string) -> (),
	ResetTable: (self: Economy, InfoToBeChanged: string) -> (),
	Get: (self: Economy, Value: string) -> number | string | { any? },
}

export type Gear = {
	new: (Player: Player, EquippedItem: string) -> Gear,
	EquipGear: (
		self: Gear,
		GearType: GearData,
		Name: string,
		ToolTip: string,
		Model: Model | Folder,
		GearId: number
	) -> (),
	UnEquipGear: (self: Gear, GearId: number) -> (),
	Get: (self: Gear) -> string?,
}

export type EconomyData = "Inventory" | "Index" | "Slots" | "RobloxInventory"
export type GearData = "Usable" | "ItemForBase"

return {}
