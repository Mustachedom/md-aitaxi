local QBCore = exports['qb-core']:GetCoreObject()
local ordered = nil
local autopilot = nil

RegisterNetEvent("md-aitaxi:client:payCheck")
AddEventHandler("md-aitaxi:client:payCheck", function() 
if ordered == nil then
TriggerServerEvent("md-aitaxi:server:PayForTaxi")
	ordered = true
else
QBCore.Functions.Notify("Already Called A Taxi")
end
end)



RegisterNetEvent("md-aitaxi:client:calltaxi")
AddEventHandler("md-aitaxi:client:calltaxi", function() 
local Ped = GetEntityCoords(PlayerPedId())
local taxidriver = Config.DriverPed
if ordered  then
	lib.requestModel(taxidriver, 500)
	lib.requestModel(`taxi`, 500)
	local aitaxi = CreateVehicle(`taxi`, Ped.x+5,Ped.y+5, Ped.z-1, 180.0, true, true)
	local taxi = CreatePed(26, taxidriver, Ped.x+5,Ped.y+5, Ped.z-1, 268.9422, true, false)
	SetVehicleOnGroundProperly(aitaxi)
	SetEntityAsMissionEntity(aitaxi)
	taxiblip = AddBlipForEntity(aitaxi)
	SetPedIntoVehicle(taxi, aitaxi, -1)
	exports[Config.Fuel]:SetFuel(aitaxi, 100.0)
	TaskVehicleDriveToCoordLongrange(taxi, aitaxi, Ped.x+2, Ped.y-1, Ped.z-1, 50.0, 60, 1.0)
	Wait(1000)
    local loc = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(aitaxi))
	Wait(2000)
	if loc < 10.0 then
	SetPedIntoVehicle(PlayerPedId(), aitaxi, 0)
	QBCore.Functions.Notify("Set A Way Point So I Know Where To Go")
	end
	repeat
		Wait(1000)
	until GetFirstBlipInfoId( 8 ) ~= 0
		if GetVehiclePedIsIn(PlayerPedId()) == aitaxi then
			local waypointBlip = GetFirstBlipInfoId( 8 )
			local coord = Citizen.InvokeNative( 0xFA7C7F0AADF25D09, waypointBlip, Citizen.ResultAsVector( ) )
			 TaskVehicleDriveToCoordLongrange(taxi, aitaxi, coord.x, coord.y, coord.z-1, 30.0, 319, 5.0)
			 SetVehicleMaxSpeed(aitaxi, 60.00)
				repeat 
					local loc2 = #(GetEntityCoords(aitaxi) - coord)
					Wait(1000)
				until loc2 < 50.0
					Wait(2000)
					TaskLeaveVehicle(PlayerPedId(), aitaxi, 0)
					Wait(1000)
					TaskVehicleDriveWander(taxi, aitaxi, 50.0, 60)
					ordered = nil
					RemoveBlip(taxiblip)
					Wait(5000)
					DeleteVehicle(aitaxi)
					DeleteEntity(taxi)
		else
			QBCore.Functions.Notify("You Left The Vehicle")
		end
	end
end)

RegisterCommand(Config.Command, function()
if ordered == nil then 
	QBCore.Functions.Notify("Calling A Taxi")
	Wait(7000)
	TriggerEvent('md-aitaxi:client:payCheck')
else
	QBCore.Functions.Notify("Already Have A Taxi")
end	
end)

RegisterNetEvent("md-aitaxi:client:autopilot")
AddEventHandler("md-aitaxi:client:autopilot", function() 
local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
if GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() then
	if IsVehicleValid(GetEntityModel(vehicle)) then
		autopilot = true
			if  GetFirstBlipInfoId( 8 ) ~= 0 then
				Wait(2000)
				local waypointBlip = GetFirstBlipInfoId( 8 ) 
				local coord = Citizen.InvokeNative( 0xFA7C7F0AADF25D09, waypointBlip, Citizen.ResultAsVector( ) ) 
				TaskVehicleDriveToCoordLongrange(PlayerPedId(), vehicle, coord.x, coord.y, coord.z-1, 30.0, 319, 20.0)
				 local loc2 = #(GetEntityCoords(PlayerPedId()) - coord)
				 print(loc2)
					if loc2 < 5.0 then
						autopilot = nil
						ClearPedTasks(PlayerPedId())
						ClearVehicleTasks(vehicle)
					end
			else
			QBCore.Functions.Notify("Set A Way Point")	
			end
	end
end
end)

RegisterCommand(Config.CommandAutopilotstop, function()
	if autopilot then
		QBCore.Functions.Notify("Already In AutoPilot Mode")
	else	
	TriggerEvent('md-aitaxi:client:autopilot')
	end
end)


RegisterCommand(Config.CommandAutopilot, function()
	autopilot = nil
	
	local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
	if vehicle then
		ClearPedTasks(PlayerPedId())
		ClearVehicleTasks(vehicle)
	end	
end)

RegisterCommand(Config.CommandStop, function()
	ordered = nil
	Wait(5000)
	ClearPedTasks(PlayerPedId())
	ClearVehicleTasks(GetVehiclePedIsIn(PlayerPedId(), true))
	local vehicle = GetVehiclePedIsIn(PlayerPedId(), true)
	if GetEntityModel(vehicle) == `taxi` then
		DeleteVehicle(GetVehiclePedIsIn(PlayerPedId(), true))
	end
end)

function IsVehicleValid(vehicleModel)
    local retval = false
    if Config.AutoPilotCars ~= nil and next(Config.AutoPilotCars) ~= nil then
        for k in pairs(Config.AutoPilotCars) do
            if Config.AutoPilotCars[k] ~= nil and GetHashKey(Config.AutoPilotCars[k]) == vehicleModel then
                retval = true
            end
        end
    end
    return retval
end
