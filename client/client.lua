local QBCore = exports['qb-core']:GetCoreObject()
local config = Config
local ordered = nil
local autoPilot = nil
local hasPaid = nil
local InTaxi = false
local IsTaxiDriving = false
local InHurryMode = false

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

local function CalculateRouteDistance(wayPointBlip, waypointCoords)
    SetBlipRoute(wayPointBlip, true)
    
    Wait(500) 

    local routeLengthMeters = GetGpsBlipRouteLength()
    print(tostring(routeLengthMeters))

    local routeLengthKilometers = routeLengthMeters / 1000.0

    TriggerServerEvent('md-aitaxi:server:CanAffordTaxi', routeLengthKilometers)
end

RegisterNetEvent('md-aitaxi:client:calltaxi', function()
	ordered = true
    local pedCoord = GetEntityCoords(cache.ped)
    local taxiDriver = config.DriverPeds[math.random(1,#config.DriverPeds)]
	ExecuteCommand('e c')
    local streetCoord = vector3(0.0, 0.0, 0.0)

    local nodeFound, nodeCoord = GetRandomVehicleNode(pedCoord.x, pedCoord.y, pedCoord.z, 100.0, true, true, true, streetCoord, 1)

    if nodeFound then
        if ordered then
            lib.requestModel(taxiDriver, 500)
            lib.requestModel(config.TaxiModel, 500)
            
            local aiTaxi = CreateVehicle(config.TaxiModel, nodeCoord.x, nodeCoord.y, nodeCoord.z, 180.0, true, true)
            local taxi = CreatePed(26, joaat(taxiDriver), nodeCoord.x, nodeCoord.y, nodeCoord.z, 268.9422, true, false)

            SetVehicleOnGroundProperly(aiTaxi)
            SetEntityAsMissionEntity(aiTaxi)
            taxiblip = AddBlipForEntity(aiTaxi)
			SetBlipSprite(taxiblip, 198)
			SetBlipScale(taxiblip, 0.5)
			SetBlipColour(taxiblip, 5)
            SetPedIntoVehicle(taxi, aiTaxi, -1)
            exports[config.Fuel]:SetFuel(aiTaxi, 100.0)

            TaskVehicleDriveToCoordLongrange(taxi, aiTaxi, pedCoord.x, pedCoord.y, pedCoord.z, 50.0, 447, 1.0)
            Wait(1000)
			
            CreateThread(function()
                while not InTaxi do
                    local loc = #(GetEntityCoords(cache.ped) - GetEntityCoords(aiTaxi))
                    Wait(100)
                    
                    if loc < 10.0 then
                        TaskVehicleTempAction(taxi, aiTaxi, 1, 1)
						local seat = math.random(1,2)
						TaskEnterVehicle(cache.ped,aiTaxi, 5000, seat, 1.0, 1, 0)
						Wait(5000)
                        QBCore.Functions.Notify('Set A Way Point So I Know Where To Go')
                        InTaxi = true
                    end
                end
            end)

            repeat
                Wait(1000)
            until InTaxi

            repeat
                Wait(1000)
            until GetFirstBlipInfoId(8) ~= 0

            if GetVehiclePedIsIn(cache.ped) == aiTaxi then
                local wayPointBlip = GetFirstBlipInfoId(8)
                local waypointCoords = GetBlipInfoIdCoord(8)
                CalculateRouteDistance(wayPointBlip, waypointCoords)

                repeat
                    Wait(1000)
                until hasPaid ~= nil

                if hasPaid then
                    if GetVehiclePedIsIn(cache.ped) == aiTaxi then
                        local coord = Citizen.InvokeNative(0xFA7C7F0AADF25D09, wayPointBlip, Citizen.ResultAsVector())
                        IsTaxiDriving = true
						local stresstick = 0
						InHurryMode = false
						local hurrying = false
						local hurrylabelshown = false
                        
                        CreateThread(function()
                            while IsTaxiDriving do
                                local currentCoord = GetEntityCoords(aiTaxi)
                                local distanceToDestination = #(currentCoord - coord)
                                
                                if distanceToDestination < 50.0 then
                                    TaskVehiclePark(taxi, aiTaxi, coord.x, coord.y, coord.z, GetEntityHeading(aiTaxi), 1, 5.0, true)
                                    IsTaxiDriving = false
                                end
								stresstick = stresstick + 1
								if stresstick >= 120 then
									if config.TaxiRelievesStress and config.TaxiRelievesStress > 0 then
										TriggerServerEvent('hud:server:RelieveStress', config.TaxiRelievesStress)
										stresstick = 0
									end
								end
                                Wait(500)
                            end
                        end)

						CreateThread(function()
                            while IsTaxiDriving do
								if config.AllowHurryMode then
									if not InHurryMode then
										if not hurrylabelshown then
											local label = "[E] Hurry $"..config.HurryTip
											exports['qb-core']:DrawText(label, 'right')
											hurrylabelshown = true
										end
                                		if IsControlJustPressed(0,38) then
											TriggerServerEvent('md-aitaxi:server:PayHurryCost')
										end
									end
									if InHurryMode and not hurrying then
										exports['qb-core']:HideText()
										TaskVehicleDriveToCoordLongrange(taxi, aiTaxi, coord.x, coord.y, coord.z - 1, 120.0, 787004, 5.0)
										SetVehicleMaxSpeed(aiTaxi, 120.00)
										QBCore.Functions.Notify('OK Ill Get There Fast')
										hurrying = true
									end
								end
                                Wait(0)
                            end
                        end)
                        
                        TaskVehicleDriveToCoordLongrange(taxi, aiTaxi, coord.x, coord.y, coord.z - 1, 30.0, 447, 5.0)
                        SetVehicleMaxSpeed(aiTaxi, 60.00)
                        
                        repeat
                            Wait(1000)
                        until not IsTaxiDriving
                        
                        TaskLeaveVehicle(cache.ped, aiTaxi, 0)
                        Wait(1000)
                        TaskVehicleDriveWander(taxi, aiTaxi, 50.0, 60)
                        ordered = nil
                        hasPaid = nil
                        InTaxi = false
						IsTaxiDriving = false
						InHurryMode = false
						exports['qb-core']:HideText()
                        RemoveBlip(taxiblip)
                        Wait(5000)
                        DeleteVehicle(aiTaxi)
                        DeleteEntity(taxi)
                    else
                        QBCore.Functions.Notify('You Left The Vehicle')
                    end
                else
                    TaskLeaveVehicle(cache.ped, aiTaxi, 0)
                    Wait(1000)
                    TaskVehicleDriveWander(taxi, aiTaxi, 50.0, 60)
                    ordered = nil
                    hasPaid = nil
                    InTaxi = false
					IsTaxiDriving = false
					InHurryMode = false
					exports['qb-core']:HideText()
                    RemoveBlip(taxiblip)
                    Wait(5000)
                    DeleteVehicle(aiTaxi)
                    DeleteEntity(taxi)
                end
            else
                QBCore.Functions.Notify('You Left The Vehicle')
            end
        end
    else
        QBCore.Functions.Notify('No Suitable Road Found Nearby')
		ordered = nil
    end
end)


RegisterNetEvent('md-aitaxi:client:hasPaid',function(bool,amount)
	if bool then
		QBCore.Functions.Notify("You Paid $"..amount)
	else
		QBCore.Functions.Notify("You Dont Have $"..amount)
	end
	hasPaid = bool
end)

RegisterNetEvent('md-aitaxi:client:HurryPaid',function(bool,amount)
	if not bool then
		QBCore.Functions.Notify("You Dont Have $"..amount)
	end
	InHurryMode = bool
end)

RegisterCommand(config.TaxiCommand, function()
	if ordered == nil then
		if Config.RequirePhoneItem then
			for k,v in pairs(Config.Phones) do
				if QBCore.Functions.HasItem(v) then
					hasphone = true
					break
				end
			end
			if hasphone then
				ExecuteCommand('e phonecall')
				QBCore.Functions.Notify('Calling A Taxi')
				Wait(7000)
				TriggerEvent('md-aitaxi:client:calltaxi')
			else
				QBCore.Functions.Notify('You Need a Phone')
			end
		else
			ExecuteCommand('e phonecall')
			QBCore.Functions.Notify('Calling A Taxi')
			Wait(7000)
			TriggerEvent('md-aitaxi:client:calltaxi')
		end
	else
		if not IsTaxiDriving then
			QBCore.Functions.Notify('Youre Taxi Is En Route!')
		else
			QBCore.Functions.Notify('Already In A Taxi')
		end
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
	if GetEntityModel(vehicle) == config.TaxiModel then
		DeleteVehicle(GetVehiclePedIsIn(cache.ped, true))
	end
end)
