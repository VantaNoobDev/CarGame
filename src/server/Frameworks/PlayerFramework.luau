--!strict
--!native
local Players = game:GetService("Players")
local Loader = require(script.Parent.Parent.Loader.Loader)
local Services = Loader.Load(script.Parent.Parent.Services)
local Types = require(script.Parent.Parent.Core.Types.ServiceTypes)

local EconomyService = Services.EconomyService :: Types.Economy
local GearService = Services.GearService :: Types.Gear

local EconomyOfPlayers = setmetatable({}, { __mode = "k" }) :: { [Player]: Types.Economy }
local GearOfPlayers = setmetatable({}, { __mode = "k" }) :: { [Player]: Types.Gear }

local Framework = {
	Join = function(Player: Player): ()
		EconomyOfPlayers[Player] = EconomyService.new(Player)
		GearOfPlayers[Player] = GearService.new(Player, "")
		return
	end,

	Leave = function(Player: Player): ()
		EconomyOfPlayers[Player] = nil
		GearOfPlayers[Player] = nil
		return
	end,
}

Players.PlayerAdded:Connect(Framework.Join)
Players.PlayerRemoving:Connect(Framework.Leave)

return {
	Notification = {}, -- No dependencies
	Gear = {
		EquipGear = function(
			Player: Player,
			GearType: Types.GearData,
			Name: string,
			ToolTip: string,
			Model: Model | Folder,
			GearId: number
		)
			local PlayerGear = GearOfPlayers[Player]
			assert(PlayerGear, "PlayerGear not found.")
			PlayerGear:EquipGear(GearType, Name, ToolTip, Model, GearId)
		end,

		UnEquippedGear = function(Player: Player, GearId: number)
			local PlayerGear = GearOfPlayers[Player]
			assert(PlayerGear, "PlayerGear not found.")
			PlayerGear:UnEquipGear(GearId)
		end,

		Get = function(Player: Player)
			local PlayerGear = GearOfPlayers[Player]
			assert(PlayerGear, "PlayerGear not found.")
			return PlayerGear:Get()
		end,
	}, -- No dependencies

	Economy = {
		AddCurrency = function(Player: Player, Amount: number, Value: Types.EconomyData)
			local PlayerEconomy = EconomyOfPlayers[Player]
			assert(PlayerEconomy, "PlayerEconomy not found.")
			PlayerEconomy:AddCurrency(Amount, Value)
		end,

		RemoveCurrency = function(Player: Player, Amount: number, Value: Types.EconomyData)
			local PlayerEconomy = EconomyOfPlayers[Player]
			assert(PlayerEconomy, "PlayerEconomy not found.")
			PlayerEconomy:RemoveCurrency(Amount, Value)
		end,

		ResetCurrency = function(Player: Player, Value: string)
			local PlayerEconomy = EconomyOfPlayers[Player]
			assert(PlayerEconomy, "PlayerEconomy not found.")
			PlayerEconomy:ResetCurrency(Value)
		end,

		AddTable = function(Player: Player, InfoToBeChanged: string, InfoToBeAdded: string, Value: Types.EconomyData)
			local PlayerEconomy = EconomyOfPlayers[Player]
			assert(PlayerEconomy, "PlayerEconomy not found.")
			PlayerEconomy:AddTable(InfoToBeChanged, InfoToBeAdded, Value)
		end,

		RemoveTable = function(
			Player: Player,
			InfoToBeChanged: string,
			InfoToBeAdded: string,
			Value: Types.EconomyData
		)
			local PlayerEconomy = EconomyOfPlayers[Player]
			assert(PlayerEconomy, "PlayerEconomy not found.")
			PlayerEconomy:RemoveTable(InfoToBeChanged, InfoToBeAdded, Value)
		end,

		ResetTable = function(Player: Player, InfoToBeChanged: string)
			local PlayerEconomy = EconomyOfPlayers[Player]
			assert(PlayerEconomy, "PlayerEconomy not found.")
			PlayerEconomy:ResetTable(InfoToBeChanged)
		end,

		Destroy = function(Player: Player)
			EconomyOfPlayers[Player] = nil
		end,

		Get = function(Player: Player, Value: string): number? | string? | boolean? | { any? }
			local PlayerEconomy = EconomyOfPlayers[Player]
			assert(PlayerEconomy, "PlayerEconomy not found.")
			return PlayerEconomy:Get(Value)
		end,
	}, -- Depends on DATA

	-- Base based. --
	Spawning = {}, -- Depends on BASE
	Stealing = {}, -- Depends on BASE, SPAWNING --

	-- Economy based. --
	Base = {}, -- Depends on ECONOMY
	Production = {}, -- Depends on ECONOMY
	Upgrade = {}, --  Depends on ECONOMY, BASE
	Shop = {}, -- Depends on ECONOMY, GEAR
	Selling = {}, -- Depends on ECONOMY, GEAR
	Leaderboard = {}, -- Depends on ECONOMY

	-- Special. --
	Admin = {}, -- Depends on everything.
	Anticheat = {}, -- Depends on everything.
}
