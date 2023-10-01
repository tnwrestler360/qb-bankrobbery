--- Threads

CreateThread(function()
    for k, v in pairs(Shared.Laptop) do
        local pedModel = v.pedModel
        lib.requestModel(pedModel)
        local laptopPed = CreatePed(0, pedModel, v.coords.x, v.coords.y, v.coords.z - 1.0, v.coords.w, false, false)
        FreezeEntityPosition(laptopPed, true)
        SetEntityInvincible(laptopPed, true)
        SetBlockingOfNonTemporaryEvents(laptopPed, true)
        
        exports['qb-target']:AddTargetEntity(laptopPed, {
            options = {
                {
                    type = 'server',
                    event = 'qb-bankrobbery:server:BuyLaptop',
                    icon = 'fas fa-hand-holding',
                    label = Locales['laptop_target_label'],
                    colour = k
                }
            },
            distance = 1.5,
        })
        
    end
end)
