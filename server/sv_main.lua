QBCore = exports['qb-core']:GetCoreObject()

robberyBusy = {
    fleeca = false,
    maze = false,
    paleto = false,
    pacific = false    
}

--- Functions

--- Method to print debug messages to console when Config.Debug is enabled
---@param message string - message to print
---@return nil
debugPrint = function(message)
    if type(message) == 'string' then
        print('^3[qb-bankrobbery] ^5' .. message .. '^7')
    end
end

--- Method to generate a random alphanumeric password with length k
---@param k number - Password length
---@return string string - Password string
generatePassword = function(k)
    local charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local string = ''

    for i = 1, k do
        local rand = math.random(#charset)
        string = string .. string.sub(charset, rand, rand)
    end

    return string
end

local ResetBank = function(bank)
    -- Door    
    Shared.Banks[bank].hacked = false
    Shared.Banks[bank].policeClose = false

    -- lockers
    for i=1, #Shared.Banks[bank].lockers, 1 do
        Shared.Banks[bank].lockers[i].busy = false
        Shared.Banks[bank].lockers[i].taken = false
    end

    -- Trollys
    ClearTrollys()
    for j=1, #Shared.Banks[bank].trolly, 1 do
        Shared.Banks[bank].trolly[j].taken = false
        Shared.Banks[bank].trolly[j].busy = false
    end

    -- Thermite spots
    if Shared.Banks[bank].thermite then
        for k=1, #Shared.Banks[bank].thermite, 1 do
            Shared.Banks[bank].thermite[k].hit = false
        end
    end

    -- Fleeca
    if Shared.Banks[bank].type == 'fleeca' then
        Shared.Banks[bank].keycardTaken = false
        Shared.Banks[bank].innerDoor.hacked = false
    end

    -- Big Banks
    if bank == 'Paleto' then
        ResetPaletoValues()
    elseif bank == 'Pacific' then
        ResetPaletoValues()
    end

    robberyBusy[Shared.Banks[bank].type] = false
    TriggerEvent('qb-scoreboard:server:SetActivityBusy', Shared.Banks[bank].type, false)
    TriggerClientEvent('qb-bankrobbery:client:ResetBank', -1, bank)
    debugPrint('Resetting ' .. bank)
end

--- Events

RegisterNetEvent('qb-bankrobbery:server:SetBankHacked', function(bank)
    if not Shared.Banks[bank] then return end
    if Shared.Banks[bank].hacked then return end

    Shared.Banks[bank].hacked = true
    robberyBusy[Shared.Banks[bank].type] = true
    TriggerEvent('qb-scoreboard:server:SetActivityBusy', Shared.Banks[bank].type, true)

    CreateTrollys(bank)

    SetTimeout(Shared.BankSettings.VaultUnlockTime * 1000, function()
        TriggerClientEvent('qb-bankrobbery:client:SetBankHacked', -1, bank)
    end)

    SetTimeout(Shared.Cooldown[Shared.Banks[bank].type] * 60 * 1000, function() -- Cooldown timer
        ResetBank(bank)
    end)
end)

RegisterNetEvent('qb-bankrobbery:server:PDClose', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local bank = data.bank
    if not Shared.Banks[bank] then return end
    
    if not Utils.PlayerIsLeo(Player.PlayerData.job) then return end

    Shared.Banks[bank].policeClose = not Shared.Banks[bank].policeClose
    TriggerClientEvent('qb-bankrobbery:client:PDClose', -1, bank)
end)

RegisterNetEvent('qb-bankrobbery:server:SetTrollyBusy', function(bank, index)
    local src = source
    local coords = GetEntityCoords(GetPlayerPed(src))
    if not Shared.Banks[bank] or not Shared.Banks[bank].trolly[index] then return end
    if #(coords - Shared.Banks[bank].trolly[index].coords.xyz) > 2.0 then return end

    Shared.Banks[bank].trolly[index].busy = true
    TriggerClientEvent('qb-bankrobbery:client:SetTrollyBusy', -1, bank, index)
end)

RegisterNetEvent('qb-bankrobbery:server:TrollyReward', function(netId, bank, index)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or type(netId) ~= 'number' or not Shared.Banks[bank] or not Shared.Banks[bank].trolly[index] then return end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if entity ~= trollies[bank][index] then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - Shared.Banks[bank].trolly[index].coords.xyz) > 10 then return end
    if Shared.Banks[bank].trolly[index].taken then return end

    TriggerClientEvent('qb-bankrobbery:client:SetTrollyTaken', -1, bank, index)
    Shared.Banks[bank].trolly[index].taken = true

    SwapTrolly(bank, index, entity)

    local bankType = Shared.Banks[bank].type
    local rewardType = Shared.Banks[bank].trolly[index].type

    if rewardType == 'money' then
        local receiveAmount = math.random(Rewards.Trollys[rewardType][bankType].minAmount, Rewards.Trollys[rewardType][bankType].maxAmount)
        
        local metaData = {
            worth = math.random(Rewards.Trollys[rewardType][bankType].minWorth, Rewards.Trollys[rewardType][bankType].maxWorth)
        }

        if Shared.Inventory == 'ox_inventory' then
            if exports['ox_inventory']:CanCarryItem(src, 'markedbills', receiveAmount) then
                exports['ox_inventory']:AddItem(src, 'markedbills', receiveAmount, metaData)
            else
                exports['ox_inventory']:CustomDrop('Bank Trolly', {
                    { 'markedbills', receiveAmount, metaData }
                }, GetEntityCoords(GetPlayerPed(src)))
                Utils.Notify(src, Locales['notify_invent_desc'], 'error', 5000)
            end
        elseif Shared.Inventory == 'qb' then
            Player.Functions.AddItem('markedbills', receiveAmount, false, metaData)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['markedbills'], 'add', receiveAmount)
        end
    elseif rewardType == 'gold' then
        local receiveAmount = math.random(Rewards.Trollys[rewardType][bankType].minAmount, Rewards.Trollys[rewardType][bankType].maxAmount)
        
        if Shared.Inventory == 'ox_inventory' then
            if exports['ox_inventory']:CanCarryItem(src, 'goldbar', receiveAmount) then
                exports['ox_inventory']:AddItem(src, 'goldbar', receiveAmount)
            else
                exports['ox_inventory']:CustomDrop('Bank Trolly', {
                    { 'goldbar', receiveAmount }
                }, GetEntityCoords(GetPlayerPed(src)))
                Utils.Notify(src, Locales['notify_invent_desc'], 'error', 5000)
            end
        elseif Shared.Inventory == 'qb' then
            Player.Functions.AddItem('goldbar', receiveAmount, false)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['goldbar'], 'add', receiveAmount)
        end
    end
end)

RegisterNetEvent('qb-bankrobbery:server:SetLockerBusy', function(bank, index)
    local src = source
    local coords = GetEntityCoords(GetPlayerPed(src))
    if not Shared.Banks[bank] or not Shared.Banks[bank].lockers[index] then return end
    if #(coords - Shared.Banks[bank].lockers[index].coords.xyz) > 5.0 then return end

    Shared.Banks[bank].lockers[index].busy = true
    TriggerClientEvent('qb-bankrobbery:client:SetLockerBusy', -1, bank, index)
end)

RegisterNetEvent('qb-bankrobbery:server:LockerReward', function(bank, index)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not Shared.Banks[bank] or not Shared.Banks[bank].lockers[index] then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - Shared.Banks[bank].lockers[index].coords.xyz) > 10 then return end
    if Shared.Banks[bank].lockers[index].taken then return end

    TriggerClientEvent('qb-bankrobbery:client:SetLockerTaken', -1, bank, index)
    Shared.Banks[bank].lockers[index].taken = true

    local bankType = Shared.Banks[bank].type

    if math.random(100) < Rewards.Lockers[bankType].rareChance then -- Rare item loot
        if Shared.Inventory == 'ox_inventory' then
            if exports['ox_inventory']:CanCarryItem(src, Rewards.Lockers[bankType].rareItem, 1) then
                exports['ox_inventory']:AddItem(src, Rewards.Lockers[bankType].rareItem, 1)
            else
                exports['ox_inventory']:CustomDrop('Bank Locker', {
                    { Rewards.Lockers[bankType].rareItem, 1 }
                }, GetEntityCoords(GetPlayerPed(src)))
                Utils.Notify(src, Locales['notify_invent_desc'], 'error', 5000)
            end
        elseif Shared.Inventory == 'qb' then
            Player.Functions.AddItem(Rewards.Lockers[bankType].rareItem, 1, false)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Rewards.Lockers[bankType].rareItem], 'add', 1)
        end 
    else
        local randomItem = Rewards.Lockers[bankType].items[math.random(#Rewards.Lockers[bankType].items)]
        local receiveAmount = math.random(Rewards.Lockers[bankType].amount.minAmount, Rewards.Lockers[bankType].amount.maxAmount)

        if Shared.Inventory == 'ox_inventory' then
            if exports['ox_inventory']:CanCarryItem(src, randomItem, receiveAmount) then
                exports['ox_inventory']:AddItem(src, randomItem, receiveAmount)
            else
                exports['ox_inventory']:CustomDrop('Bank Locker', {
                    { randomItem, receiveAmount }
                }, GetEntityCoords(GetPlayerPed(src)))
                Utils.Notify(src, Locales['notify_invent_desc'], 'error', 5000)
            end
        elseif Shared.Inventory == 'qb' then
            Player.Functions.AddItem(randomItem, receiveAmount, false)
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[randomItem], 'add', receiveAmount)
        end
    end
end)

RegisterNetEvent('qb-bankrobbery:server:RemoveThermite', function()
    local src = source
    if Shared.Inventory == 'ox_inventory' then
        exports['ox_inventory']:RemoveItem(src, 'thermite', 1, false)
    elseif Shared.Inventory == 'qb' then
        local Player = QBCore.Functions.GetPlayer(src)
        if not Player then return end

        Player.Functions.RemoveItem('thermite', 1)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['thermite'], 'remove', 1)
    end
end)

RegisterNetEvent('qb-bankrobbery:server:SetThermiteHit', function(bank, index)
    Shared.Banks[bank].thermite[index].hit = true
    TriggerClientEvent('qb-bankrobbery:client:SetThermiteHit', -1, bank, index)
end)

RegisterNetEvent('qb-bankrobbery:server:ThermitePtfx', function(bank, index)
    local src = source
    local coords = Shared.Banks[bank].thermite[index].ptfx
    TriggerClientEvent('qb-bankrobbery:client:ThermitePtfx', -1, coords)

    Wait(27000)
    Utils.DoorUpdate(src, Shared.Banks[bank].thermite[index].doorId, 0)
end)

--- Callbacks

lib.callback.register('qb-bankrobbery:server:GetConfig', function(source)
    return Shared
end)

lib.callback.register('qb-bankrobbery:server:CanAttemptBankRobbery', function(source, bank)
    local src = source
    local bankType = Shared.Banks[bank].type

    if robberyBusy[bankType] then
        Utils.Notify(src, Locales['bank_cooldown'], 'error', 4000)
        return false
    elseif Utils.GetCopCount() < Shared.MinCops[bankType] then
        Utils.Notify(src, Locales['not_enough_cops']:format(Shared.MinCops[bankType]), 'error', 4000)
        return false
    else
        return true
    end
end)

--- Items

QBCore.Functions.CreateUseableItem('thermite', function(source, item)
    TriggerClientEvent('thermite:UseThermite', source)
end)
