Utils = {}

Utils.AlertCops = function(bankType)
    if GetResourceState('ps-dispatch') ~= 'started' then return end

    if copsCalled then return end

    copsCalled = true

    if bankType == 'fleeca' then
        exports['ps-dispatch']:FleecaBankRobbery()
    elseif bankType == 'maze' then
        exports['ps-dispatch']:FleecaBankRobbery()
    elseif bankType == 'paleto' then
        exports['ps-dispatch']:PaletoBankRobbery()
    elseif bankType == 'pacific' then
        exports['ps-dispatch']:PacificBankRobbery()
    end

    CreateThread(function()
        Wait(5 * 60 * 1000)
        copsCalled = false
    end)
end

Utils.Notify = function(message, notifType, timeOut)
    if Shared.Notify == 'qb' then
        QBCore.Functions.Notify(message, notifType, timeOut)
    elseif Shared.Notify == 'ox' then
        lib.notify({
            title = Locales['notify_title'],
            description = message,
            duration = timeOut,
            type = notifType,
            position = 'center-right',
        })
    end
end
