--!strict
--!native
local Players = game:GetService("Players")
local Loader = require(script.Parent.Parent.Loader.Loader)
local Services = Loader.Load(script.Parent.Parent.Services)
local Types = require(script.Parent.Parent.Core.Types.ServiceTypes)

local EconomyService = Services.EconomyService :: Types.Economy
local GearService = Services.GearService :: Types.Gear
local BaseService = Services.BaseService :: Types.Base

local EconomyOfPlayers: { [Player]: Types.Economy } = {}
local GearOfPlayers: { [Player]: Types.Gear } = {}
local BaseOfPlayers: { [Player]: Types.Base } = {}

local Framework = {
	Join = function(Player: Player): ()
		EconomyOfPlayers[Player] = EconomyService.new(Player)
		GearOfPlayers[Player] = GearService.new(Player)
		BaseOfPlayers[Player] = BaseService.new(Player)

		BaseOfPlayers[Player]:AddToBase()
		GearOfPlayers[Player]:EquipGear("Usable", "Slap glove.", "Use it to slap people!", Instance.new("Model"), 1)
	end,

	Leave = function(Player: Player): ()
		if EconomyOfPlayers[Player] then
			EconomyOfPlayers[Player]:Destroy()
			EconomyOfPlayers[Player] = nil
		end

		if GearOfPlayers[Player] then
			GearOfPlayers[Player]:Destroy()
			GearOfPlayers[Player] = nil
		end

		if BaseOfPlayers[Player] then
			BaseOfPlayers[Player]:Destroy()
			BaseOfPlayers[Player] = nil
		end
	end,
}

Players.PlayerAdded:Connect(Framework.Join)
Players.PlayerRemoving:Connect(Framework.Leave)

local function GetEconomy(Player: Player): Types.Economy
	local e = EconomyOfPlayers[Player]
	assert(e, `No EconomyService instance found for {Player.Name}.`)
	return e
end

local function GetGear(Player: Player): Types.Gear
	local g = GearOfPlayers[Player]
	assert(g, `No GearService instance found for {Player.Name}.`)
	return g
end

local function GetBase(Player: Player): Types.Base
	local b = BaseOfPlayers[Player]
	assert(b, `No BaseService instance found for {Player.Name}.`)
	return b
end

return {
	-- No dependencies --
	Notification = {},

	Gear = {
		EquipGear = function(
			Player: Player,
			GearType: Types.GearData,
			Name: string,
			ToolTip: string,
			Model: Model | Folder,
			GearId: number
		): ()
			GetGear(Player):EquipGear(GearType, Name, ToolTip, Model, GearId)
		end,

		UnEquipGear = function(Player: Player, GearId: number): ()
			GetGear(Player):UnEquipGear(GearId)
		end,

		Get = function(Player: Player): string
			return GetGear(Player):Get()
		end,
	},

	Economy = {
		AddCurrency = function(Player: Player, Amount: number, Value: Types.EconomyData): ()
			GetEconomy(Player):AddCurrency(Amount, Value)
		end,

		RemoveCurrency = function(Player: Player, Amount: number, Value: Types.EconomyData): ()
			GetEconomy(Player):RemoveCurrency(Amount, Value)
		end,

		ResetCurrency = function(Player: Player, Value: Types.EconomyData): ()
			GetEconomy(Player):ResetCurrency(Value)
		end,

		AddTable = function(
			Player: Player,
			InfoToBeChanged: string,
			InfoToBeAdded: string,
			Value: Types.EconomyData
		): ()
			GetEconomy(Player):AddTable(InfoToBeChanged, InfoToBeAdded, Value)
		end,

		RemoveTable = function(
			Player: Player,
			InfoToBeChanged: Types.EconomyData,
			InfoToBeRemoved: string,
			Value: Types.EconomyData
		): ()
			GetEconomy(Player):RemoveTable(InfoToBeChanged, InfoToBeRemoved, Value)
		end,

		ResetTable = function(Player: Player, InfoToBeChanged: Types.EconomyData): ()
			GetEconomy(Player):ResetTable(InfoToBeChanged)
		end,

		Get = function(Player: Player, Value: Types.EconomyData): number | string | { any? }
			return GetEconomy(Player):Get(Value)
		end,
	},

	Base = {
		AddToBase = function(Player: Player): ()
			GetBase(Player):AddToBase()
		end,

		RemoveFromBase = function(Player: Player): ()
			GetBase(Player):RemoveFromBase()
		end,
	},

	-- Base based.
	Spawning = {}, -- Depends on BASE
	Stealing = {}, -- Depends on BASE, SPAWNING

	-- Economy based.
	Production = {}, -- Depends on ECONOMY
	Upgrade = {}, -- Depends on ECONOMY, BASE
	Shop = {}, -- Depends on ECONOMY, GEAR
	Selling = {}, -- Depends on ECONOMY, GEAR
	Leaderboard = {}, -- Depends on ECONOMY

	-- Special.
	Admin = {}, -- Depends on everything.
	Anticheat = {}, -- Depends on everything.
}
