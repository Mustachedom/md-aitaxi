local QBCore = exports['qb-core']:GetCoreObject()

RegisterServerEvent('md-aitaxi:server:PayForTaxi', function()
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)

	if Player.Functions.RemoveMoney('cash', Config.Price) or Player.Functions.RemoveMoney('bank', Config.Price) then
		TriggerClientEvent('md-aitaxi:client:calltaxi', src)
	end
end)
