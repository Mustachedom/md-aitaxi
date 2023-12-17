local QBCore = exports['qb-core']:GetCoreObject()
local config = Config

RegisterServerEvent('md-aitaxi:server:PayForTaxi', function()
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)

	if Player.Functions.RemoveMoney('cash', config.Price) or Player.Functions.RemoveMoney('bank', config.Price) then
		TriggerClientEvent('md-aitaxi:client:calltaxi', src)
	end
end)
