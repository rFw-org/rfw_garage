function GetLicense(id)
    local identifiers = GetPlayerIdentifiers(id)
    for _, v in pairs(identifiers) do
        if string.find(v, "license") then
            return v
        end
    end
end

local playerVehCache = {}
RegisterNetEvent("rFw:GetPlayerVehicles")
AddEventHandler("rFw:GetPlayerVehicles", function()
    local source = source
    local license = GetLicense(source)
    if playerVehCache[license] == nil then
        local info = MySQL.Sync.fetchAll("SELECT owned, stored, props, mileage FROM players_veh WHERE owner = @identifier", {
            ['@identifier'] = license
        })

        playerVehCache[license] = {}
        for k,v in pairs(info) do
            local decodedProps = json.decode(info[k].props)
            playerVehCache[license][#playerVehCache[license] + 1] = {props = decodedProps, owned = info[k].owned, stored = info[k].stored, mileage = info[k].mileage}
        end
        TriggerClientEvent("rFw:GetPlayerVehicles", source, playerVehCache[license])
    else
        TriggerClientEvent("rFw:GetPlayerVehicles", source, playerVehCache[license])
    end
end)

RegisterNetEvent("rFw:SendVehToGarage")
AddEventHandler("rFw:SendVehToGarage", function(props, plate, net)
    local source = source
    local license = GetLicense(source)
    local encodedProps = json.encode(props)

    local info = MySQL.Sync.fetchAll("SELECT plate, owned FROM players_veh WHERE plate = @plate", {
        ['@plate'] = plate 
    })

    if info[1] == nil then
        MySQL.Async.execute("INSERT INTO `players_veh` (`owner`, `owned`, `plate`, `stored`, `props`) VALUES ('"..license.."', '0', '"..plate.."', '1', '"..encodedProps.."')", {}, function()end)
        playerVehCache[license][#playerVehCache[license] + 1] = {props = props, owned = 0, stored = 1, mileage = 0.0}
        Citizen.InvokeNative(`DELETE_ENTITY` & 0xFFFFFFFF, NetworkGetEntityFromNetworkId(net))
        TriggerClientEvent("rFw:GetPlayerVehicles", source, playerVehCache[license])
    elseif info[1].owned == 1 then
        -- Do an props update, compare encoded props in cache with new props

        for k,v in pairs(playerVehCache[license]) do
            if v.props.plate == plate then
                playerVehCache[license][k].stored = 1
                if encodedProps ~= json.encode(v.props) then
                    MySQL.Async.execute("UPDATE `players_veh` SET props = '"..encodedProps.."' WHERE plate = '"..plate.."'", {}, function()end)
                    playerVehCache[license][k].props = props
                    print("^2GARAGE: ^7Updating props for "..plate.."")
                end
                break
            end
        end
        Citizen.InvokeNative(`DELETE_ENTITY` & 0xFFFFFFFF, NetworkGetEntityFromNetworkId(net))
        TriggerClientEvent("rFw:GetPlayerVehicles", source, playerVehCache[license])
    else
        TriggerClientEvent("rFw:CantEnterVeh", source)
    end
end)

RegisterNetEvent("rFw:DeleteVehFromGarage")
AddEventHandler("rFw:DeleteVehFromGarage", function(plate)
    local source = source
    local license = GetLicense(source)
    MySQL.Async.execute("DELETE FROM players_veh WHERE plate = '"..plate.."' AND owner = '"..license.."'", {}, function()end)
    for k,v in pairs(playerVehCache[license]) do
        if v.props.plate == plate then
            playerVehCache[license][k] = nil
        end
    end
    TriggerClientEvent("rFw:GetPlayerVehicles", source, playerVehCache[license])
end)

RegisterNetEvent("rFw:SetVehStatus")
AddEventHandler("rFw:SetVehStatus", function(plate)
    local source = source
    local license = GetLicense(source)
    for k,v in pairs(playerVehCache[license]) do
        if v.props.plate == plate then
            playerVehCache[license][k].stored = 0
        end
    end
    TriggerClientEvent("rFw:GetPlayerVehicles", source, playerVehCache[license])
end)