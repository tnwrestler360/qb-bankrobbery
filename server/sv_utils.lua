Utils = {}

Utils.PlayerIsLeo = function(Job)
    -- return Job.name == 'police' and Job.onduty
    return Job.type == 'leo' and Job.onduty
end

Utils.GetCopCount = function()
    local amount = 0
    local players = QBCore.Functions.GetQBPlayers()

    for _, Player in pairs(players) do
        if Utils.PlayerIsLeo(Player.PlayerData.job) then
            amount += 1
        end
    end

    return amount
end

Utils.Notify = function(source, message, notifType, timeOut)
    if Shared.Notify == 'qb' then
        TriggerClientEvent('QBCore:Notify', source, message, notifType, timeOut)
    elseif Shared.Notify == 'ox' then
        TriggerClientEvent('ox_lib:notify', source, {
            title = Locales['notify_title'],
            description = message,
            duration = timeOut,
            type = notifType,
            position = 'center-right',
        })
    end
end

Utils.PhoneMail = function(source, citizenid, sender, subject, message)
    if Shared.Phone == 'QBCore' then
        -- Older, using event
        TriggerEvent('qb-phone:server:sendNewMailToOffline', citizenid, {
            sender = sender,
            subject = subject,
            message = message
        })

        -- Recent, using export
        -- exports['qb-phone']:sendNewMailToOffline(citizenid, {
        --     sender = sender,
        --     subject = subject,
        --     message = message
        -- })
    elseif Shared.Phone == 'GKS' then
        exports['gksphone']:SendNewMail(source, {
            sender = sender,
            image = '/html/static/img/icons/mail.png',
            subject = subject,
            message = message
        })
    elseif Shared.Phone == 'Qs' then
        TriggerEvent('qs-smartphone:server:sendNewMailToOffline', citizenid, {
            sender = sender,
            subject = subject,
            message = message
        })
    elseif Shared.Phone == 'lb-phone' then
        local number = exports['lb-phone']:GetEquippedPhoneNumber(source)
        local mail = exports['lb-phone']:GetEmailAddress(number)

        exports['lb-phone']:SendMail({
            to = mail,
            subject = subject,
            message = message
        })
    end
end

Utils.DoorUpdate = function(source, doorId, state)
    if Shared.Doorlock == 'ox' then
        state = state and 1 or 0
        TriggerEvent('ox_doorlock:setState', exports['ox_doorlock']:getDoorFromName(doorId).id, 0)
    elseif Shared.Doorlock == 'qb' then
        TriggerEvent('qb-doorlock:server:updateState', doorId, false, false, false, true, false, false, source)
    end
end
