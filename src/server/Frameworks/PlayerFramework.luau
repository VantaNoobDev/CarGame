--!strict
--!native
local Players = game:GetService("Players")
local SpawnerService = game:GetService("SpawnerService")
local Loader = require(script.Parent.Parent.Loader.Loader)
local Services = Loader.Load(script.Parent.Parent.Services)
local Types = require(script.Parent.Parent.Core.Types.ServiceTypes)

local EconomyService = Services.EconomyService :: Types.Economy

local EconomyOfPlayers: { [Player]: Types.Economy } = {}

local Framework = {
	Join = function(Player: Player): ()
		EconomyOfPlayers[Player] = EconomyService.new(Player)
		return
	end,

	Leave = function(Player: Player): ()
		EconomyOfPlayers[Player] = nil
		return
	end,
}

Players.PlayerAdded:Connect(Framework.Join)
Players.PlayerRemoving:Connect(Framework.Leave)

return {
	Notification = {}, -- No dependencies
	Economy = {
		AddCurrency = function(Player: Player, Amount: number, Value: string)
			local PlayerEconomy = EconomyOfPlayers[Player]
			assert(PlayerEconomy, "PlayerEconomy not found.")
			if PlayerEconomy then
				PlayerEconomy:AddCurrency(Amount, Value)
			end
		end,

		RemoveCurrency = function(Player: Player, Amount: number, Value: string)
			local PlayerEconomy = EconomyOfPlayers[Player]
			assert(PlayerEconomy, "PlayerEconomy not found.")
			if PlayerEconomy then
				PlayerEconomy:RemoveCurrency(Amount, Value)
			end
		end,

		ResetCurrency = function(Player: Player, Value: string)
			local PlayerEconomy = EconomyOfPlayers[Player]
			assert(PlayerEconomy, "PlayerEconomy not found.")
			if PlayerEconomy then
				PlayerEconomy:ResetCurrency(Value)
			end
		end,

		AddTable = function(Player: Player, InfoToBeChanged: string, InfoToBeAdded: string, Value: string)
			local PlayerEconomy = EconomyOfPlayers[Player]
			assert(PlayerEconomy, "PlayerEconomy not found.")
			if PlayerEconomy then
				PlayerEconomy:AddTable(InfoToBeChanged, InfoToBeAdded, Value)
			end
		end,

		RemoveTable = function(Player: Player, InfoToBeChanged: string, InfoToBeAdded: string, Value: string)
			local PlayerEconomy = EconomyOfPlayers[Player]
			assert(PlayerEconomy, "PlayerEconomy not found.")
			if PlayerEconomy then
				PlayerEconomy:RemoveTable(InfoToBeChanged, InfoToBeAdded, Value)
			end
		end,

		ResetTable = function(Player: Player, InfoToBeChanged: string)
			local PlayerEconomy = EconomyOfPlayers[Player]
			assert(PlayerEconomy, "PlayerEconomy not found.")
			if PlayerEconomy then
				PlayerEconomy:ResetTable(InfoToBeChanged)
			end
		end,

		Destroy = function(Player: Player)
			EconomyOfPlayers[Player] = nil
		end,

		Get = function(Player: Player, Value: string): number? | string? | boolean? | { any? }
			local PlayerEconomy = EconomyOfPlayers[Player]
			assert(PlayerEconomy, "PlayerEconomy not found.")
			if PlayerEconomy then
				return PlayerEconomy:Get(Value)
			end
			return nil
		end,
	}, -- Depends on DATA

	-- Base based. --
	Spawning = {}, -- Depends on BASE

	-- Economy based. --
	Base = {}, -- Depends on ECONOMY
	Production = {}, -- Depends on ECONOMY
	Upgrade = {}, --  Depends on BASE, ECONOMY
	Gear = {}, -- Depends on ECONOMY
	Shop = {}, -- Depends on ECONOMY, GEAR
	Leaderboard = {}, -- Depends on ECONOMY

	-- Special. --
	Admin = {}, -- Depends on everything.
	Anticheat = {}, -- Depends on everything.
}
