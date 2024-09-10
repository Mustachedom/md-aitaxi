local QBCore = exports['qb-core']:GetCoreObject()
local config = Config
local AvailableTaxi = 0

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then
        return
    end
    if Config.TaxiLimit then
        AvailableTaxi = Config.TaxiLimit
    end
end)

QBCore.Functions.CreateCallback('md-aitaxi:server:GetAvailableTaxi', function(source, cb)
    if AvailableTaxi >= 1 then
        cb(true)
    else
        cb(false)
    end
end)

RegisterNetEvent('md-aitaxi:server:TaxiUsage',function(isUse)
    if inUse then
        AvailableTaxi = AvailableTaxi - 1
    else
        AvailableTaxi = AvailableTaxi + 1
    end
    -- print(tostring(AvailableTaxi))
end)

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