--- Events

RegisterNetEvent('qb-bankrobbery:server:GrabFleecaKeycard', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    local bank = data.bank
    if not Player or not Shared.Banks[bank] then return end

    local pos = GetEntityCoords(GetPlayerPed(src))
    if #(pos - Shared.Banks[bank].coords) > 15.0 then return end
    
    local bankType = Shared.Banks[bank].type
    if bankType ~= 'fleeca' then return end

    if Shared.Banks[bank].keycardTaken then
        Utils.Notify(src, Locales['keycard_taken'], 'error', 3000)
        return
    end

    if Utils.GetCopCount() < Shared.MinCops[bankType] then
        Utils.Notify(src, Locales['not_enough_cops']:format(Shared.MinCops[bankType]), 'error', 4000)
        return
    end

    Shared.Banks[bank].keycardTaken = true

    if Shared.Inventory == 'ox_inventory' then
        local metaData = { bank = bank }
        exports['ox_inventory']:AddItem(src, 'fleeca_bankcard', 1, metaData)
    elseif Shared.Inventory == 'qb' then
        local info = { bank = bank }
        Player.Functions.AddItem('fleeca_bankcard', 1, false, info)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['fleeca_bankcard'], 'add', 1)
    end

    TriggerClientEvent('qb-bankrobbery:client:SetFleecaCardTaken', -1, bank)
end)

RegisterNetEvent('qb-bankrobbery:server:HackInnerPanel', function(bank)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player or not Shared.Banks[bank] then return end

    Shared.Banks[bank].innerDoor.hacked = true

    Utils.DoorUpdate(src, Shared.Banks[bank].innerDoor.id, 0)
    TriggerClientEvent('qb-bankrobbery:client:SetInnerHacked', -1, bank)
end)

--- Items

QBCore.Functions.CreateUseableItem('fleeca_bankcard', function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local coords = GetEntityCoords(GetPlayerPed(src))

    if Shared.Inventory == 'ox_inventory' then
        local items = exports['ox_inventory']:Search(src, 1, 'fleeca_bankcard')
    
        if items[1] then
            if #(coords - Shared.Banks[items[1].metadata.bank].door.coords) < 2.0 then
                if Utils.GetCopCount() >= Shared.MinCops['fleeca'] then
                    exports['ox_inventory']:RemoveItem(src, items[1].name, 1, nil, items[1].slot)
                    Utils.DoorUpdate(src, Shared.Banks[items[1].metadata.bank].door.id, 0)
                    Utils.Notify(src, Locales['keycard_used'], 'success', 3000)
                else
                    Utils.Notify(src, Locales['not_enough_cops']:format(Shared.MinCops['fleeca']), 'error', 3000)
                end
            end
        end
    elseif Shared.Inventory == 'qb' then
        if not item.info.bank then return end
        if #(coords - Shared.Banks[item.info.bank].door.coords) < 2.0 then
            if Utils.GetCopCount() >= Shared.MinCops['fleeca'] then
                if Player.Functions.RemoveItem('fleeca_bankcard', 1, false) then
                    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['fleeca_bankcard'], 'remove', 1)
                    Utils.DoorUpdate(src, Shared.Banks[item.info.bank].door.id, 0)
                    Utils.Notify(src, Locales['keycard_used'], 'success', 3000)
                end
            else
                Utils.Notify(src, Locales['not_enough_cops']:format(Shared.MinCops['fleeca']), 'error', 3000)
            end
        end
    end
end)
