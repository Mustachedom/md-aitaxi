local QBCore = exports['qb-core']:GetCoreObject()
local config = Config
local ordered = nil
local autoPilot = nil

RegisterNetEvent('md-aitaxi:client:payCheck', function()
	if ordered == nil then
		TriggerServerEvent('md-aitaxi:server:PayForTaxi')
		ordered = true
	else
		QBCore.Functions.Notify('Already Called A Taxi')
	end
end)

RegisterNetEvent('md-aitaxi:client:calltaxi', function()
	local pedCoord = GetEntityCoords(cache.ped)
	local taxiDriver = config.DriverPed
	if ordered then
		lib.requestModel(taxiDriver, 500)
		lib.requestModel(`taxi`, 500)
		local aiTaxi = CreateVehicle(`taxi`, pedCoord.x + 5, pedCoord.y + 5, pedCoord.z - 1, 180.0, true, true)
		local taxi = CreatePed(26, joaat(taxiDriver), pedCoord.x + 5, pedCoord.y + 5, pedCoord.z - 1, 268.9422, true, false)
		SetVehicleOnGroundProperly(aiTaxi)
		SetEntityAsMissionEntity(aiTaxi)
		taxiblip = AddBlipForEntity(aiTaxi)
		SetPedIntoVehicle(taxi, aiTaxi, -1)
		exports[config.Fuel]:SetFuel(aiTaxi, 100.0)
		TaskVehicleDriveToCoordLongrange(taxi, aiTaxi, pedCoord.x + 2, pedCoord.y - 1, pedCoord.z - 1, 50.0, 60, 1.0)
		Wait(1000)
		local loc = #(GetEntityCoords(cache.ped) - GetEntityCoords(aiTaxi))
		Wait(2000)
		if loc < 10.0 then
			SetPedIntoVehicle(cache.ped, aiTaxi, 0)
			QBCore.Functions.Notify('Set A Way Point So I Know Where To Go')
		end
		repeat
			Wait(1000)
		until GetFirstBlipInfoId(8) ~= 0
		if GetVehiclePedIsIn(cache.ped) == aiTaxi then
			local wayPointBlip = GetFirstBlipInfoId(8)
			local coord = Citizen.InvokeNative(0xFA7C7F0AADF25D09, wayPointBlip, Citizen.ResultAsVector())
			TaskVehicleDriveToCoordLongrange(taxi, aiTaxi, coord.x, coord.y, coord.z - 1, 30.0, 319, 5.0)
			SetVehicleMaxSpeed(aiTaxi, 60.00)
			repeat
				local loc2 = #(GetEntityCoords(aiTaxi) - coord)
				Wait(1000)
			until loc2 < 50.0
			Wait(2000)
			TaskLeaveVehicle(cache.ped, aiTaxi, 0)
			Wait(1000)
			TaskVehicleDriveWander(taxi, aiTaxi, 50.0, 60)
			ordered = nil
			RemoveBlip(taxiblip)
			Wait(5000)
			DeleteVehicle(aiTaxi)
			DeleteEntity(taxi)
		else
			QBCore.Functions.Notify('You Left The Vehicle')
		end
	end
end)

RegisterCommand(config.TaxiCommand, function()
	if ordered == nil then
		QBCore.Functions.Notify('Calling A Taxi')
		Wait(7000)
		TriggerEvent('md-aitaxi:client:payCheck')
	else
		QBCore.Functions.Notify('Already Have A Taxi')
	end
end)

RegisterNetEvent('md-aitaxi:client:autopilot', function()
	local vehicle = GetVehiclePedIsIn(cache.ped, true)
	if GetPedInVehicleSeat(vehicle, -1) == cache.ped then
		if IsVehicleValid(GetEntityModel(vehicle)) then
			autoPilot = true
			if GetFirstBlipInfoId(8) ~= 0 then
				Wait(2000)
				local wayPointBlip = GetFirstBlipInfoId(8)
				local coord = Citizen.InvokeNative(0xFA7C7F0AADF25D09, wayPointBlip, Citizen.ResultAsVector())
				TaskVehicleDriveToCoordLongrange(cache.ped, vehicle, coord.x, coord.y, coord.z - 1, 30.0, 319, 20.0)
				local loc2 = #(GetEntityCoords(cache.ped) - coord)
				print(loc2)
				if loc2 < 5.0 then
					autoPilot = nil
					ClearPedTasks(cache.ped)
					ClearVehicleTasks(vehicle)
				end
			else
				QBCore.Functions.Notify('Set A Way Point')
			end
		end
	end
end)

RegisterCommand(config.AutopilotCommand, function()
	if autopilot then
		QBCore.Functions.Notify('Already In AutoPilot Mode')
	else
		TriggerEvent('md-aitaxi:client:autopilot')
	end
end)


RegisterCommand(config.AutopilotstopCommand, function()
	autoPilot = nil

	local vehicle = GetVehiclePedIsIn(cache.ped, true)
	if vehicle then
		ClearPedTasks(cache.ped)
		ClearVehicleTasks(vehicle)
	end
end)

RegisterCommand(config.TaxiStopCommand, function()
	ordered = nil
	Wait(5000)
	ClearPedTasks(cache.ped)
	ClearVehicleTasks(GetVehiclePedIsIn(cache.ped, true))
	local vehicle = GetVehiclePedIsIn(cache.ped, true)
	if GetEntityModel(vehicle) == `taxi` then
		DeleteVehicle(GetVehiclePedIsIn(cache.ped, true))
	end
end)

local function IsVehicleValid(vehicleModel)
	local retval = false
	if config.AutoPilotCars ~= nil and next(config.AutoPilotCars) ~= nil then
		for k in pairs(config.AutoPilotCars) do
			if config.AutoPilotCars[k] ~= nil and GetHashKey(config.AutoPilotCars[k]) == vehicleModel then
				retval = true
			end
		end
	end
	return retval
end
