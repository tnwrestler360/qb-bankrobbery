RegisterNetEvent('qb-bankrobbery:server:BuyLaptop', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local colour = data.colour
    if not Player or not Shared.Laptop[colour] then return end
    local pos = GetEntityCoords(GetPlayerPed(src))
    if #(pos - Shared.Laptop[colour].coords.xyz) > 5.0 then return end

    if Shared.Inventory == 'ox_inventory' then
        local items = exports['ox_inventory']:Search(src, 'count', Shared.Laptop[colour].usb)
        if items > 0 then
            if Player.Functions.RemoveMoney(Shared.LaptopMoneyType, Shared.Laptop[colour].price, 'bankrobbery-buy-laptop') then
                exports['ox_inventory']:RemoveItem(src, Shared.Laptop[colour].usb, 1)
    
                local metaData = { uses = Shared.LaptopUses }
                exports['ox_inventory']:AddItem(src, Shared.Laptop[colour].reward, 1, metaData)
                debugPrint(Player.PlayerData.name .. ' (citizenid: ' .. Player.PlayerData.citizenid .. ' | id: ' .. src .. ') Purchased ' .. Shared.Laptop[colour].reward .. ' for ' .. Shared.Laptop[colour].price .. ' ' .. Shared.LaptopMoneyType)
            else
                Utils.Notify(src, Locales['laptop_not_enough']:format(Shared.LaptopMoneyType), 'error', 3000)
            end
        end
    elseif Shared.Inventory == 'qb' then
        if Player.Functions.GetItemByName(Shared.Laptop[colour].usb) then
            if Player.Functions.RemoveMoney(Shared.LaptopMoneyType, Shared.Laptop[colour].price, 'bankrobbery-buy-laptop') then
                Player.Functions.RemoveItem(Shared.Laptop[colour].usb, 1, false)
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Shared.Laptop[colour].usb], 'remove', 1)
    
                local info = { uses = Shared.LaptopUses }
                Player.Functions.AddItem(Shared.Laptop[colour].reward, 1, false, info)
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Shared.Laptop[colour].reward], 'add', 1)
                
                debugPrint(Player.PlayerData.name .. ' (citizenid: ' .. Player.PlayerData.citizenid .. ' | id: ' .. src .. ') Purchased ' .. Shared.Laptop[colour].reward .. ' for ' .. Shared.Laptop[colour].price .. ' ' .. Shared.LaptopMoneyType)
            else
                Utils.Notify(src, Locales['laptop_not_enough']:format(Shared.LaptopMoneyType), 'error', 3000)
            end
        end
    end
end)

RegisterNetEvent('qb-bankrobbery:server:LaptopDamage', function(itemName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if Shared.Inventory == 'ox_inventory' then
        local items = exports['ox_inventory']:Search(src, 1, itemName)
        if items[1] and items[1].count > 0 then
            if items[1].metadata.uses == nil then
                items[1].metadata.uses = Shared.LaptopUses - 1
                exports['ox_inventory']:SetMetadata(src, items[1].slot, items[1].metadata)
                debugPrint(Player.PlayerData.name .. ' has a ' .. items[1].name .. ' without info.uses!')
                return
            end
    
            if (items[1].metadata.uses - 1) <= 0 then
                exports['ox_inventory']:RemoveItem(src, items[1].name, 1, nil, items[1].slot)
            else
                items[1].metadata.uses -= 1
                exports['ox_inventory']:SetMetadata(src, items[1].slot, items[1].metadata)
            end
        end
    elseif Shared.Inventory == 'qb' then
        local item = Player.Functions.GetItemByName(itemName)
        if not item then return end
    
        if not item.info.uses then
            Player.PlayerData.items[item.slot].info.uses = Shared.LaptopUses - 1
            Player.Functions.SetInventory(Player.PlayerData.items)
            debugPrint(Player.PlayerData.name .. ' has a ' .. item.name .. ' without info.uses!')
            return
        end
    
        if (item.info.uses - 1) <= 0 then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item.name], 'remove', 1)
            Player.Functions.RemoveItem(item.name, 1, item.slot)
        else
            Player.PlayerData.items[item.slot].info.uses = Player.PlayerData.items[item.slot].info.uses - 1
            Player.Functions.SetInventory(Player.PlayerData.items)
        end
    end
end)
