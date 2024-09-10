local QBCore = exports['qb-core']:GetCoreObject()
local config = Config
local ordered = nil
local autoPilot = nil
local hasPaid = nil
local InTaxi = false
local IsTaxiDriving = false
local InHurryMode = false
local taxiblip = nil

local function DebugCode(msg)
	if config.DebugCode then
		print(msg)
	end
end

local function ShowDrawtext(text,show)
	if config.Drawtext == 'qb' then
		if show then
			exports['qb-core']:DrawText(text, 'left')
		else
			exports['qb-core']:HideText()
		end
	elseif config.Drawtext == 'ps-ui' then
		if show then 
			exports['ps-ui']:DisplayText(text, 'primary')
		else
			exports['ps-ui']:HideText()
		end
	end
end

local function FuelSystem(vehicle,amount)
	if config.Fuel == 'LegacyFuel' then
		exports['LegacyFuel']:SetFuel(vehicle, amount)
	end
end

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

local function SortTaxiBlip(vehicle)
	if taxiblip ~= nil then
		RemoveBlip(taxiblip)
	end
	taxiblip = AddBlipForEntity(vehicle)
	SetBlipSprite(taxiblip, 198)
	SetBlipScale(taxiblip, 0.5)
	SetBlipColour(taxiblip, 5)
end

local function CalculateRouteDistance(wayPointBlip, waypointCoords)
    SetBlipRoute(wayPointBlip, true)
    
    Wait(500) 

    local routeLengthMeters = GetGpsBlipRouteLength()
    DebugCode(tostring(routeLengthMeters))

    local routeLengthKilometers = routeLengthMeters / 1000.0

    TriggerServerEvent('md-aitaxi:server:CanAffordTaxi', routeLengthKilometers)
end

local function GetClosestDepot(myCoord)
    local closestDepot = nil
    local shortestDistance = math.huge

    for _, v in pairs(config.TaxiDepots) do
        local distance = math.sqrt(
            (myCoord.x - v.x)^2 +
            (myCoord.y - v.y)^2 +
            (myCoord.z - v.z)^2
        )

        if distance < shortestDistance then
            shortestDistance = distance
            closestDepot = {
                x = v.x,
                y = v.y,
                z = v.z,
                w = v.w,
            }
        end
    end

    return closestDepot
end

local function RemovePlayerFromTaxi(taxiVehicle, taxiDriver)
	TaskLeaveVehicle(cache.ped, taxiVehicle, 0)
    Wait(2000)
    TaskVehicleDriveWander(taxiDriver, taxiVehicle, 50.0, config.PassiveDrivingStyle)
    ordered = nil
    hasPaid = nil
    InTaxi = false
	IsTaxiDriving = false
	InHurryMode = false
	ShowDrawtext(nil,false)
    RemoveBlip(taxiblip)
    Wait(30000)
    DeleteVehicle(taxiVehicle)
    DeleteEntity(taxiDriver)
	TriggerServerEvent('md-aitaxi:server:TaxiUsage',true)
end

local function PlayerLeftVehicle()
	TriggerServerEvent('md-aitaxi:server:TaxiUsage',true) 
	QBCore.Functions.Notify('You Left The Vehicle')
	ShowDrawtext(nil,false)
end

RegisterNetEvent('md-aitaxi:client:calltaxi', function()
	ordered = true
    local pedCoord = GetEntityCoords(cache.ped)
    local taxiDriver = config.DriverPeds[math.random(1,#config.DriverPeds)]
	ExecuteCommand('e c')
    local streetCoord = vector3(0.0, 0.0, 0.0)

    local nodeFound, nodeCoord = GetRandomVehicleNode(pedCoord.x, pedCoord.y, pedCoord.z, 1000.0, true, true, true, streetCoord, 1)

    if nodeFound then
        if ordered then
			TriggerServerEvent('md-aitaxi:server:TaxiUsage',false)
			QBCore.Functions.Notify("Taxi Is En Route")
            lib.requestModel(taxiDriver, 500)
            lib.requestModel(config.TaxiModel, 500)
			local aiTaxi = nil
			local taxi = nil

            if not config.TaxiSpawnsAtClosestDepot then
            	aiTaxi = CreateVehicle(config.TaxiModel, nodeCoord.x, nodeCoord.y, nodeCoord.z, 180.0, true, true)
            	taxi = CreatePed(26, joaat(taxiDriver), nodeCoord.x, nodeCoord.y, nodeCoord.z, 268.9422, true, false)
			else
				local closestDepot = GetClosestDepot(pedCoord)
				aiTaxi = CreateVehicle(config.TaxiModel, closestDepot.x, closestDepot.y, closestDepot.z, 180.0, true, true)
            	taxi = CreatePed(26, joaat(taxiDriver), closestDepot.x, closestDepot.y, closestDepot.z, 268.9422, true, false)
				SetEntityHeading(aiTaxi, closestDepot.w)
			end

            SetVehicleOnGroundProperly(aiTaxi)
            SetEntityAsMissionEntity(aiTaxi)
			SortTaxiBlip(aiTaxi)
            SetPedIntoVehicle(taxi, aiTaxi, -1)
			FuelSystem(aitaxi, 100.0)

            TaskVehicleDriveToCoordLongrange(taxi, aiTaxi, pedCoord.x, pedCoord.y, pedCoord.z, config.PassiveDriveSpeed, config.PassiveDrivingStyle, 1.0)
            Wait(1000)
			
            CreateThread(function()
                while not InTaxi do
                    local loc = #(GetEntityCoords(cache.ped) - GetEntityCoords(aiTaxi))
                    Wait(100)
                    
                    if loc < 20.0 then
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
                Wait(100)
            until InTaxi

            repeat
                Wait(100)
            until GetFirstBlipInfoId(8) ~= 0

            if GetVehiclePedIsIn(cache.ped) == aiTaxi then
                local wayPointBlip = GetFirstBlipInfoId(8)
                local waypointCoords = GetBlipInfoIdCoord(8)
                CalculateRouteDistance(wayPointBlip, waypointCoords)

                repeat
                    Wait(100)
                until hasPaid ~= nil

                if hasPaid then
                    if GetVehiclePedIsIn(cache.ped) ~= aiTaxi then 
						PlayerLeftVehicle()
						return 
					end
					local coord = GetBlipInfoIdCoord(wayPointBlip)
                    IsTaxiDriving = true
					local stresstick = 0
					InHurryMode = false
					local hurrying = false
					local hurrylabelshown = false
                    
                    CreateThread(function()
                        while IsTaxiDriving do
							if GetVehiclePedIsIn(cache.ped) ~= aiTaxi then
								IsTaxiDriving = false
							end
                            local currentCoord = GetEntityCoords(aiTaxi)
                            local distanceToDestination = #(currentCoord - coord)
                            
                            if distanceToDestination < 50.0 then
								TaskVehicleTempAction(taxi, aiTaxi, 1, 20)
								Wait(1000)
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
										ShowDrawtext(label,true)
										hurrylabelshown = true
									end
                            		if IsControlJustPressed(0,38) then
										TriggerServerEvent('md-aitaxi:server:PayHurryCost')
									end
								end
								if InHurryMode and not hurrying then
									ShowDrawtext(nil,false)
									TaskVehicleDriveToCoordLongrange(taxi, aiTaxi, coord.x, coord.y, coord.z - 1, config.HurryDriveSpeed, Config.HurryDrivingStyle, 5.0)
									SetVehicleMaxSpeed(aiTaxi, 120.00)
									QBCore.Functions.Notify('OK Ill Get There Fast')
									hurrying = true
								end
							end
                            Wait(0)
                        end
                    end)
                    
                    TaskVehicleDriveToCoordLongrange(taxi, aiTaxi, coord.x, coord.y, coord.z - 1, config.PassiveDriveSpeed, config.PassiveDrivingStyle, 5.0)
                    SetVehicleMaxSpeed(aiTaxi, 60.00)
                    
                    repeat
                        Wait(100)
                    until not IsTaxiDriving
                    
					RemovePlayerFromTaxi(aiTaxi, taxi)
                else
					RemovePlayerFromTaxi(aiTaxi, taxi)
                end
            else
                PlayerLeftVehicle()
            end
        end
    else
        QBCore.Functions.Notify('No Suitable Road Found Nearby')
		ShowDrawtext(nil,false)
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

local function hasPhone()
	local retval = false
	if config.RequirePhoneItem then
		for k,v in pairs(config.Phones) do
			if QBCore.Functions.HasItem(v) then
				retval = true
				break
			end
		end
	else
		retval = true
	end
	return retval
end

RegisterCommand(config.TaxiCommand, function()
	if ordered == nil then
		if hasPhone() then
			if config.TaxiLimit then
				QBCore.Functions.TriggerCallback('md-aitaxi:server:GetAvailableTaxi', function(available)
					if available then
						ExecuteCommand('e phonecall')
						QBCore.Functions.Notify('Calling A Taxi')
						Wait(7000)
						TriggerEvent('md-aitaxi:client:calltaxi')
					else
						QBCore.Functions.Notify('All Our Taxi Are Busy Right Now')
					end
				end)
			else
				ExecuteCommand('e phonecall')
				QBCore.Functions.Notify('Calling A Taxi')
				Wait(7000)
				TriggerEvent('md-aitaxi:client:calltaxi')
			end
		else
			QBCore.Functions.Notify('You Need a Phone')
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
				local coord = GetBlipInfoIdCoord(wayPointBlip)
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
	ShowDrawtext(nil,false)
	Wait(5000)
	ClearPedTasks(cache.ped)
	ClearVehicleTasks(GetVehiclePedIsIn(cache.ped, true))
	local vehicle = GetVehiclePedIsIn(cache.ped, true)
	if GetEntityModel(vehicle) == config.TaxiModel then
		DeleteVehicle(GetVehiclePedIsIn(cache.ped, true))
	end
	TriggerServerEvent('md-aitaxi:server:TaxiUsage',true)
end)
