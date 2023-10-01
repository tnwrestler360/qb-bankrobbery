local usbItems = {
    'pacific_key1',
    'pacific_key2',
    'pacific_key3',
    'pacific_key4'
}

local vaultCodes = {
    [1] = generatePassword(4),
    [2] = generatePassword(4),
}

local checkingPacificPasscode = false
local pacificInputCorrect = false
local pacificInputCache = {
    [1] = false,
    [2] = false
}

--- Functions

ResetPacificValues = function()
    Shared.Banks['Pacific'].lockdown = false
    Shared.Banks['Pacific'].laserPanel = false
    Shared.Banks['Pacific'].sideEntrance.hacked = false
    Shared.Banks['Pacific'].computers['main'].hacked = false
    Shared.Banks['Pacific'].computers['office1'].hacked = false
    Shared.Banks['Pacific'].computers['office2'].hacked = false
    Shared.Banks['Pacific'].computers['office3'].hacked = false
    Shared.Banks['Pacific'].computers['office4'].hacked = false
    Shared.Banks['Pacific'].sideVaults[1].hacked = false
    Shared.Banks['Pacific'].sideVaults[2].hacked = false

    vaultCodes = {
        [1] = generatePassword(4),
        [2] = generatePassword(4),
    }

    checkingPacificPasscode = false
    pacificInputCorrect = false
    pacificInputCache = {
        [1] = false,
        [2] = false
    }
    
    for i = 1, 4, 1 do
        local drawer = math.random(#Shared.Banks['Pacific'].searchDrawers)

        while Shared.Banks['Pacific'].searchDrawers[drawer].usb do
            drawer = math.random(#Shared.Banks['Pacific'].searchDrawers)
        end

        Shared.Banks['Pacific'].searchDrawers[drawer].usb = true
        debugPrint('Pacific Drawer USB: ' .. drawer)
    end

    debugPrint('Pacific Code 1: ' .. vaultCodes[1])
    debugPrint('Pacific Code 2: ' .. vaultCodes[2])
end

--- Events

RegisterNetEvent('qb-bankrobbery:server:SetPacificSideHacked', function()
    local src = source
    if Shared.Banks['Pacific'].sideEntrance.hacked then return end

    Shared.Banks['Pacific'].sideEntrance.hacked = true
    TriggerClientEvent('qb-bankrobbery:client:SetPacificSideHacked', -1)

    Utils.DoorUpdate(src, Shared.Banks['Pacific'].sideEntrance.id, 0)
end)

RegisterNetEvent('qb-bankrobbery:server:SetPacificComputerHacked', function(computer)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Shared.Banks['Pacific'].computers[computer] then return end
    if Shared.Banks['Pacific'].computers[computer].hacked then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - Shared.Banks['Pacific'].computers[computer].coords) > 5 then return end

    Shared.Banks['Pacific'].computers[computer].hacked = true
    TriggerClientEvent('qb-bankrobbery:client:SetPacificComputerHacked', -1, computer)

    if computer == 'main' then
        TriggerClientEvent('var-ui:on', src, vaultCodes[1])

        -- Instruction Email
        Utils.PhoneMail(src, Player.PlayerData.citizenid, Locales['pacific_mail_sender'], Locales['pacific_mail_subject'], Locales['pacific_mail_text1']:format(vaultCodes[1]) .. Locales['pacific_mail_text2'])

        -- Unlock Doors
        Utils.DoorUpdate(src, 'bankrobbery-pacific-door1', 0)
        Utils.DoorUpdate(src, 'bankrobbery-pacific-door2', 0)
        Utils.DoorUpdate(src, 'bankrobbery-pacific-door3', 0)
        Utils.DoorUpdate(src, 'bankrobbery-pacific-door4', 0)

        return
    elseif computer == 'office1' then
        TriggerClientEvent('var-ui:on', src, string.sub(vaultCodes[2], 1, 1) .. '...')
    elseif computer == 'office2' then
        TriggerClientEvent('var-ui:on', src, '.' .. string.sub(vaultCodes[2], 2, 2) .. '..')
    elseif computer == 'office3' then
        TriggerClientEvent('var-ui:on', src, '..' .. string.sub(vaultCodes[2], 3, 3) .. '.')
    elseif computer == 'office4' then
        TriggerClientEvent('var-ui:on', src, '...' .. string.sub(vaultCodes[2], 4, 4))
    else
        return
    end

    if Shared.Inventory == 'ox_inventory' then
        exports['ox_inventory']:RemoveItem(src, Shared.Banks['Pacific'].computers[computer].key, 1, false)
    elseif Shared.Inventory == 'qb' then
        Player.Functions.RemoveItem(Shared.Banks['Pacific'].computers[computer].key, 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Shared.Banks['Pacific'].computers[computer].key], 'remove', 1)
    end
end)

RegisterNetEvent('qb-bankrobbery:server:SearchDrawer', function(drawer)
    if not Shared.Banks['Pacific'].searchDrawers[drawer] then return end
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if #(GetEntityCoords(GetPlayerPed(src)) - Shared.Banks['Pacific'].searchDrawers[drawer].coords.xyz) > 10 then return end

    if Shared.Banks['Pacific'].searchDrawers[drawer].usb then
        local random = math.random(#usbItems)
        local item = usbItems[random]

        Shared.Banks['Pacific'].searchDrawers[drawer].usb = false
        table.remove(usbItems, random)
        Utils.Notify(src, Locales['pacific_found_datakey'], 'success', 3000)

        if Shared.Inventory == 'ox_inventory' then
            if exports['ox_inventory']:CanCarryItem(src, item, 1) then
                exports['ox_inventory']:AddItem(src, item, 1)
            else
                exports['ox_inventory']:CustomDrop('Drawer', {
                    { item, 1 }
                }, GetEntityCoords(GetPlayerPed(src)))
                Utils.Notify(src, Locales['notify_invent_desc'], 'error', 5000)
            end
        elseif Shared.Inventory == 'qb' then
            Player.Functions.AddItem(item, 1)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'add', 1)
        end
    else
        Utils.Notify(src, Locales['pacific_found_no_datakey'], 'error', 3000)
    end
end)

RegisterNetEvent('qb-bankrobbery:server:EnterPacificCode', function(panel, input)
    local src = source
    if not vaultCodes[panel] then return end
    if not Shared.Banks['Pacific'].computers['main'].hacked then return end

    if vaultCodes[panel] == input then
        pacificInputCache[panel] = true

        if not checkingPacificPasscode then
            checkingPacificPasscode = true

            SetTimeout(Shared.BankSettings.PacificInputTime, function()
                if pacificInputCache[1] and pacificInputCache[2] then
                    pacificInputCorrect = true
                    Utils.Notify(src, Locales['pacific_input_authorized'], 'success', 3000)

                    Utils.DoorUpdate(src, 'bankrobbery-vault-door1', 0)
                    Utils.DoorUpdate(src, 'bankrobbery-vault-door2', 0)

                    CreateTrollys('Pacific')
                else
                    Utils.Notify(src, Locales['pacific_input_timing'], 'error', 3000)

                    pacificInputCache[1] = false
                    pacificInputCache[2] = false
                    checkingPacificPasscode = false
                end
            end)

        end
    else
        Utils.Notify(src, Locales['pacific_input_incorrect'], 'error', 3000)
    end
end)

RegisterNetEvent('qb-bankrobbery:server:HitByLaser', function()
    local src = source
    if Shared.Banks['Pacific'].lockdown then return end

    Shared.Banks['Pacific'].lockdown = true
    TriggerClientEvent('qb-bankrobbery:client:SetLockdownActive', -1)

    Utils.Notify(src, Locales['pacific_hitbylaser'], 'inform', 3000)
end)

RegisterNetEvent('qb-bankrobbery:server:LaserPowerSupplyDisabled', function()
    if Shared.Banks['Pacific'].lockdown then return end
    if Shared.Banks['Pacific'].laserPanel then return end

    Shared.Banks['Pacific'].laserPanel = true
    TriggerClientEvent('qb-bankrobbery:client:LaserPowerSupplyDisabled', -1)
end)

RegisterNetEvent('qb-bankrobbery:server:PacificSideVaultHacked', function(vault)
    local src = source
    if not Shared.Banks['Pacific'].sideVaults[vault] then return end
    if Shared.Banks['Pacific'].lockdown then return end
    if Shared.Banks['Pacific'].sideVaults[vault].hacked then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - Shared.Banks['Pacific'].sideVaults[vault].laptop.xyz) > 5 then return end

    Shared.Banks['Pacific'].sideVaults[vault].hacked = true
    TriggerClientEvent('qb-bankrobbery:client:PacificSideVaultHacked', -1, vault)

    Utils.DoorUpdate(src, Shared.Banks['Pacific'].sideVaults[vault].id, 0)
end)

--- Callbacks

lib.callback.register('qb-bankrobbery:server:CanAttemptPacificHack', function(source)
    local src = source
    if Shared.Banks['Pacific'].sideEntrance.hacked then
        Utils.Notify(src, Locales['pacific_sidehack_hit'], 'error', 4000)
        return false
    elseif Utils.GetCopCount() < Shared.MinCops['pacific'] then
        Utils.Notify(src, Locales['not_enough_cops']:format(Shared.MinCops['pacific']), 'error', 4000)        
        return false
    else
        return true
    end
end)

--- Threads

CreateThread(function()
    for i = 1, 4, 1 do
        local drawer = math.random(#Shared.Banks['Pacific'].searchDrawers)

        while Shared.Banks['Pacific'].searchDrawers[drawer].usb do
            drawer = math.random(#Shared.Banks['Pacific'].searchDrawers)
        end
        
        Shared.Banks['Pacific'].searchDrawers[drawer].usb = true
        debugPrint('Pacific Drawer USB: ' .. drawer)
    end

    debugPrint('Pacific Code 1: ' .. vaultCodes[1])
    debugPrint('Pacific Code 2: ' .. vaultCodes[2])

end)
