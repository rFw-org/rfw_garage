


Citizen.CreateThread(function()
    while true do
        local pPed = GetPlayerPed(-1)
        local pCoords = GetEntityCoords(pPed)
        local nearGarage = false
        for k,v in pairs(config.zone) do
            if #(pCoords - v.pos) < 2.0 then
                nearGarage = true
                ShowHelpNotification("Press ~INPUT_PICKUP~ to open garage")
                if IsControlJustReleased(0, 38) then
                    OpenGarage(v)
                end
            end
        end


        if nearGarage then
            Wait(1)
        else
            Wait(500)
        end
    end
end)


local menuOpen = false
local vehicles = {}

RegisterNetEvent("rFw:GetPlayerVehicles")
AddEventHandler("rFw:GetPlayerVehicles", function(vehs)
    vehicles = vehs
end)

RegisterNetEvent("rFw:CantEnterVeh")
AddEventHandler("rFw:CantEnterVeh", function()
    ShowNotification("Sorry, this vehicle can't be stored.")
end)

RMenu.Add('garage', 'main', RageUI.CreateMenu("Garage", ""))
RMenu:Get('garage', 'main'):SetSubtitle("~b~Garage action menu")
RMenu:Get('garage', 'main').EnableMouse = false
RMenu:Get('garage', 'main').Closed = function()
    menuOpen = false
end



function OpenGarage(info)
    if menuOpen then
        menuOpen = false
    else
        menuOpen = true
        RageUI.Visible(RMenu:Get('garage', 'main'), true)
        TriggerServerEvent("rFw:GetPlayerVehicles")

        Citizen.CreateThread(function()
            while menuOpen do
                RageUI.IsVisible(RMenu:Get('garage', 'main'), true, true, true, function()
                    RageUI.Button("Ranger vehicle", "Store latest vehicle you were in or vehicle you are in.", true, function(Hovered, Active, Selected)
                        if (Selected) then
                            if IsPedInAnyVehicle(GetPlayerPed(-1), false) then
                                local veh = GetVehiclePedIsIn(GetPlayerPed(-1), false)
                                if veh ~= 0 then
                                    local props = GetVehicleProperties(veh)
                                    local plate = props.plate
                                    TriggerServerEvent("rFw:SendVehToGarage", props, plate, VehToNet(veh))
                                end
                            else
                                local veh = GetVehiclePedIsIn(GetPlayerPed(-1), true)
                                if veh ~= 0 then
                                    local props = GetVehicleProperties(veh)
                                    local plate = props.plate
                                    TriggerServerEvent("rFw:SendVehToGarage", props, plate, VehToNet(veh))
                                end
                            end
                        end
                    end)


                    for k,v in pairs(vehicles) do
                        if v.stored == 1 then
                            RageUI.Button(GetDisplayNameFromVehicleModel(v.props.model).." ~b~["..v.props.plate.."]", nil, true, function(Hovered, Active, Selected)
                                if (Selected) then
                                    local spawn, heading = SelectRandomSpawn(info.out)
                                    if spawn ~= false then
                                        RequestModel(v.props.model)
                                        while not HasModelLoaded(v.props.model) do Wait(1) end
                                        local veh = CreateVehicle(v.props.model, spawn, heading, 1, 0)
                                        SetVehicleProperties(veh, v.props)
                                        SetEntityAsMissionEntity(veh, 1, 1)
                                        if v.owned == 0 then
                                            TriggerServerEvent("rFw:DeleteVehFromGarage", v.props.plate)
                                        else
                                            TriggerServerEvent("rFw:SetVehStatus", v.props.plate)
                                        end
                                    else
                                        ShowNotification("No spawnpoint avalaibler.")
                                    end
                                end
                            end)
                        else
                            RageUI.Button(GetDisplayNameFromVehicleModel(v.props.model).." ~b~["..v.props.plate.."] - ~r~OUT", nil, true, function(_, _, _)
                            end)
                        end
                    end 
            
                end, function()
                end)
                Wait(1)
            end
        end)

    end
end


function SelectRandomSpawn(zone)
    local count = 0
    for k,v in pairs(zone) do
        count = count + 1
        local r = zone[math.random(1, #zone)]
        if IsSpawnPointClear(r.pos, 2.0) then
            return r.pos, r.heading
        end

        if count >= #zone then
            break
        end
    end
    return false
end