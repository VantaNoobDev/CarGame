--!strict
--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Red = require(ReplicatedStorage.Packages.Red)
local EconomyService = require(script.Parent.EconomyService)

local ShopService = {}
ShopService.__index = ShopService

return ShopService
