local QBCore = exports['qb-core']:GetCoreObject()
local config = Config

RegisterServerEvent('md-aitaxi:server:CanAffordTaxi', function(distance)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local payment = math.floor(distance * config.PricePerKM)
    
    if Player.Functions.GetMoney('cash') >= payment then
        Player.Functions.RemoveMoney('cash', payment)
        TriggerClientEvent('md-aitaxi:client:hasPaid', src, true, payment)
    elseif Player.Functions.GetMoney('bank') >= payment then
        Player.Functions.RemoveMoney('bank', payment)
        TriggerClientEvent('md-aitaxi:client:hasPaid', src, true, payment)
    else
        TriggerClientEvent('md-aitaxi:client:hasPaid', src, false, payment)
    end
end)

RegisterServerEvent('md-aitaxi:server:PayHurryCost', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
	local payment = Config.HurryTip
    
    if Player.Functions.GetMoney('cash') >= payment then
        Player.Functions.RemoveMoney('cash', payment)
        TriggerClientEvent('md-aitaxi:client:HurryPaid', src, true, payment)
    elseif Player.Functions.GetMoney('bank') >= payment then
        Player.Functions.RemoveMoney('bank', payment)
        TriggerClientEvent('md-aitaxi:client:HurryPaid', src, true, payment)
    else
        TriggerClientEvent('md-aitaxi:client:HurryPaid', src, false, payment)
    end
end)