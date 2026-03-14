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

return {}
