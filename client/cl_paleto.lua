local paletoCameras = {
    [1] = { 'Security Hallway', vector4(-99.98, 6476.69, 32.8, 190.82), -1557675482 },
    [2] = { 'Main Lobby #1', vector4(-102.22, 6475.49, 32.8, 171.44), -712148387 },
    [3] = { 'Main Lobby #2', vector4(-107.87, 6461.35, 32.8, 3.29), -712148387 },
    [4] = { 'Office #1', vector4(-101.9, 6460.61, 32.8, 75.81), 595161168 },
    [5] = { 'Office #2', vector4(-97.53, 6465.04, 32.8, 1.67), 1122715848 },
    [6] = { 'Administration Office', vector4(-105.73, 6480.59, 32.8, 189.21), 1297762420 },
    [7] = { 'Front Exit', vector4(-103.24, 6451.46, 32.8, 86.55), 0 },
    [8] = { 'Back Exit', vector4(-88.88, 6467.08, 32.8, 337.9), 0 },
}

--- Camera Menu

local cameraOptions = {}

for k, v in ipairs(paletoCameras) do
	cameraOptions[#cameraOptions + 1] = {
		title = v[1],
		icon = 'video',
		event = 'qb-bankrobbery:client:PaletoCamera',
		arrow = true,
		args = k
	}
end

lib.registerContext({
	id = 'bankrobbery_paleto_cam',
	title = Locales['paleto_camera_header'],
	options = cameraOptions
})

--- Events

RegisterNetEvent('qb-bankrobbery:client:PaletoSideHacks', function(data)
    if Shared.Banks['Paleto'][data.hack].hacked then return end
    lib.callback('qb-bankrobbery:server:CanAttemptPaletoHack', false, function(canAttempt)
        if canAttempt then
            local ped = cache.ped
            TaskTurnPedToFaceEntity(ped, data.entity, 1.0)

            if lib.progressBar({
                duration = math.random(5000, 10000),
                label = Locales['paleto_progressbar_sidehack'],
                useWhileDead = false,
                canCancel = true,
                disable = { car = true, move = true, combat = true, mouse = false },
                anim = { dict = 'anim@gangops@facility@servers@', clip = 'hotwire', flag = 16 }
            }) then 
                Utils.AlertCops(Shared.Banks['Paleto'].type)
                exports['varhack']:OpenHackingGame(function(success)
                    if success then 
                        PlaySound(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', 0, 0, 1)
                        TriggerServerEvent('qb-bankrobbery:server:SetPaletoSideHacked', data.hack)
                    else
                        Utils.Notify(Locales['paleto_sidehack_fail'], 'error', 3000)
                    end
                end, Shared.MinigameSettings.varHack.blocks, 7)
            else
                Utils.Notify(Locales['canceled'], 'error', 3000)
            end
        end
    end, data.hack)
end)

RegisterNetEvent('qb-bankrobbery:client:SetPaletoSideHacked', function(hack)
    Shared.Banks['Paleto'][hack].hacked = true
end)

RegisterNetEvent('qb-bankrobbery:client:PaletoCameraControls', function()
    if not Shared.Banks['Paleto'].sideHack.hacked then return end
    
    lib.showContext('bankrobbery_paleto_cam')
end)

RegisterNetEvent('qb-bankrobbery:client:PaletoCamera', function(id)
    if not paletoCameras[id] then return end
    if not Shared.Banks['Paleto'].sideHack.hacked then return end

    local coords = paletoCameras[id][2]
    PaletoCamera(coords, paletoCameras[id][3])
end)

RegisterNetEvent('qb-bankrobbery:client:PaletoHacksMenu', function()
    if not Shared.Banks['Paleto'].sideHack.hacked then return end

    local options = {}

    for k, v in ipairs(Shared.Banks['Paleto'].officeHacks) do
        options[#options + 1] = {
            title = v.label,
            disabled = v.hacked,
            icon = 'user-secret',
            event = 'qb-bankrobbery:client:PaletoHack',
            args = k
        }
    end

    lib.registerContext({
		id = 'bankrobbery_paleto_hack',
		title = Locales['paleto_hacks_header'],
		options = options
	})

    lib.showContext('bankrobbery_paleto_hack')
end)

RegisterNetEvent('qb-bankrobbery:client:PaletoHack', function(id)
    if Shared.Banks['Paleto'].officeHacks[id].hacked then return end

    local ped = cache.ped
    lib.requestAnimDict('anim@heists@prison_heiststation@cop_reactions')
    TaskPlayAnim(ped, 'anim@heists@prison_heiststation@cop_reactions', 'cop_b_idle', 1.0, 1.0, -1, 1, 0, 0, 0, 0)
    exports['casinohack']:OpenHackingGame(function(success)
        if success then 
            PlaySound(-1, 'Lose_1st', 'GTAO_FM_Events_Soundset', 0, 0, 1)
            TriggerServerEvent('qb-bankrobbery:server:SetPaletoOfficeHacked', id)
        else
            Utils.Notify(Locales['paleto_office_hack_fail'], 'error', 3000)
            TriggerServerEvent('qb-bankrobbery:server:SetPaletoOfficeHacked', id)--added 
        end
        StopAnimTask(ped, 'anim@heists@prison_heiststation@cop_reactions', 'cop_b_idle', 1.0)
    end, Shared.MinigameSettings.mazeHack.time)
    
end)

RegisterNetEvent('qb-bankrobbery:client:SetPaletoOfficeHacked', function(id)
    Shared.Banks['Paleto'].officeHacks[id].hacked = true
end)

RegisterNetEvent('qb-bankrobbery:client:OfficePassword', function(data)
    local ped = cache.ped
    local pos = GetEntityCoords(ped)

    -- EVIDENCE
    if not QBCore.Functions.IsWearingGloves() then
        TriggerServerEvent('evidence:server:CreateFingerDrop', pos)
    end
    
    -- ENTERING CODE
    lib.requestAnimDict('anim@heists@prison_heiststation@cop_reactions')
    TaskPlayAnim(ped, 'anim@heists@prison_heiststation@cop_reactions', 'cop_b_idle', 1.0, 1.0, -1, 1, 0, 0, 0, 0)
    
    local input = lib.inputDialog(Locales['paleto_input_header'], {
        {
            type = 'input', 
            label = '',
            placeholder = 'XXXXX',
            icon = 'user-shield',
            required = true
        },
    })

    StopAnimTask(ped, 'anim@heists@prison_heiststation@cop_reactions', 'cop_b_idle', 1.0)

    if not input then return end
    local pass = string.upper(input[1])
    print(data.office)
    TriggerServerEvent('qb-bankrobbery:server:EnterPaletoPassword', data.office, pass)
end)

RegisterNetEvent('qb-bankrobbery:client:UseBlueLaptop', function(data)
    if Shared.Inventory == 'ox_inventory' and exports['ox_inventory']:Search('count', 'laptop_blue') == 0 then
        Utils.Notify(Locales['missing_items'], 'error', 3000)
        return
    elseif Shared.Inventory == 'qb' and not QBCore.Functions.HasItem('laptop_blue') then
        Utils.Notify(Locales['missing_items'], 'error', 3000)
        return
    end

    lib.callback('qb-bankrobbery:server:CanPaletoBankPanelHack', false, function(canAttempt)
        if canAttempt then
            local ped = cache.ped
            TaskTurnPedToFaceEntity(ped, data.entity, 1.0)

            if lib.progressBar({
                duration = math.random(5000, 10000),
                label = Locales['progressbar_laptop'],
                useWhileDead = false,
                canCancel = true,
                disable = { car = true, move = true, combat = true, mouse = false },
                anim = { dict = 'anim@gangops@facility@servers@', clip = 'hotwire', flag = 16 }
            }) then 
                TriggerServerEvent('qb-bankrobbery:server:LaptopDamage', 'laptop_blue')
                LaptopAnimation('Paleto')
            else
                Utils.Notify(Locales['canceled'], 'error', 3000)
            end
        else
            Utils.Notify(Locales['paleto_lockdown'], 'error', 4500)

            Wait(5000)

            Utils.Notify(Locales['paleto_lockdown2'], 'error', 4500)
        end
    end)
end)

--- Threads

CreateThread(function()
    -- Side Entrance Panel
    exports['qb-target']:AddBoxZone('bankrobbery_sidepanel_paleto', vector3(-115.55, 6480.31, 31.80), 0.4, 0.2, {
        name = 'bankrobbery_sidepanel_paleto',
        heading = 315,
        debugPoly = Shared.Debug,
        minZ = 31.80,
        maxZ = 32.10
     }, {
        options = { 
            {
                type = 'client',
                event = 'qb-bankrobbery:client:PaletoSideHacks',
                icon = 'fas fa-user-secret',
                label = Locales['paleto_target_sidehack'],
                canInteract = function()
                    return not Shared.Banks['Paleto'].sideEntrance.hacked
                end,
                hack = 'sideEntrance'
            }
        },
        distance = 1.0,
    })

    -- Side Entrance Inside Hack
    exports['qb-target']:AddBoxZone('bankrobbery_sidehack_paleto', vector3(-118.04, 6470.28, 30.80), 1.4, 0.3, {
        name = 'bankrobbery_backpanel_paleto',
        heading = 225,
        debugPoly = Shared.Debug,
        minZ = 30.80,
        maxZ = 32.80
     }, {
        options = { 
            {
                type = 'client',
                event = 'qb-bankrobbery:client:PaletoSideHacks',
                icon = 'fas fa-user-secret',
                label = Locales['paleto_target_sidehack'],
                canInteract = function()
                    return not Shared.Banks['Paleto'].sideHack.hacked
                end,
                hack = 'sideHack'
            }
        },
        distance = 1.0,
    })

    -- Security Entrance Panel
    exports['qb-target']:AddBoxZone('bankrobbery_backpanel_paleto', vector3(-95.52, 6473.04, 31.80), 0.4, 0.2, {
        name = 'bankrobbery_backpanel_paleto',
        heading = 225,
        debugPoly = Shared.Debug,
        minZ = 31.80,
        maxZ = 32.10
     }, {
        options = { 
            {
                type = 'client',
                event = 'qb-bankrobbery:client:PaletoSideHacks',
                icon = 'fas fa-user-secret',
                label = Locales['paleto_target_sidehack'],
                canInteract = function()
                    return not Shared.Banks['Paleto'].securityEntrance.hacked
                end,
                hack = 'securityEntrance'
            }
        },
        distance = 1.0,
    })

    -- Security Room Camera Panel
    exports['qb-target']:AddBoxZone('bankrobbery_paleto_camera', vector3(-92.86, 6463.76, 31.40), 0.7, 0.4, {
        name = 'bankrobbery_paleto_camera',
        heading = 320,
        debugPoly = Shared.Debug,
        minZ = 31.40,
        maxZ = 31.70
     }, {
        options = { 
            {
                type = 'client',
                event = 'qb-bankrobbery:client:PaletoCameraControls',
                icon = 'fas fa-video',
                label = Locales['paleto_camera_target'],
                canInteract = function()
                    return Shared.Banks['Paleto'].sideHack.hacked
                end
            }
        },
        distance = 1.0,
    })

    -- Security Room Hack Panel
    exports['qb-target']:AddBoxZone('bankrobbery_paleto_hacks', vector3(-91.76, 6464.88, 31.40), 0.6, 0.4, {
        name = 'bankrobbery_paleto_hacks',
        heading = 325,
        debugPoly = Shared.Debug,
        minZ = 31.40,
        maxZ = 31.70
     }, {
        options = { 
            {
                type = 'client',
                event = 'qb-bankrobbery:client:PaletoHacksMenu',
                icon = 'fas fa-user-secret',
                label = Locales['paleto_target_office_hack'],
                canInteract = function()
                    return Shared.Banks['Paleto'].sideHack.hacked
                end
            }
        },
        distance = 1.0,
    })
    
    -- Office 1 Hack
    exports['qb-target']:AddBoxZone('bankrobbery_paleto_office_1', vector3(-98.24, 6466.1, 31.40), 0.8, 0.6, {
        name = 'bankrobbery_paleto_office_1',
        heading = 315,
        debugPoly = Shared.Debug,
        minZ = 31.40,
        maxZ = 31.70
     }, {
        options = { 
            {
                type = 'client',
                event = 'qb-bankrobbery:client:OfficePassword',
                icon = 'fas fa-terminal',
                label = Locales['paleto_input_header'],
                canInteract = function()
                    return Shared.Banks['Paleto'].officeHacks[1].hacked
                end,
                office = 1,
            }
        },
        distance = 1.5,
    })

    -- Office 2 Hack
    exports['qb-target']:AddBoxZone('bankrobbery_paleto_office_2', vector3(-103.83, 6460.49, 31.40), 0.8, 0.6, {
        name = 'bankrobbery_paleto_office_2',
        heading = 315,
        debugPoly = Shared.Debug,
        minZ = 31.40,
        maxZ = 31.70
     }, {
        options = { 
            {
                type = 'client',
                event = 'qb-bankrobbery:client:OfficePassword',
                icon = 'fas fa-terminal',
                label = Locales['paleto_input_header'],
                canInteract = function()
                    return Shared.Banks['Paleto'].officeHacks[2].hacked
                end,
                office = 2,
            }
        },
        distance = 1.5,
    })

    -- Office 3 Hack
    exports['qb-target']:AddBoxZone('bankrobbery_paleto_office_3', vector3(-104.68, 6479.34, 31.40), 0.8, 0.6, {
        name = 'bankrobbery_paleto_office_3',
        heading = 315,
        debugPoly = Shared.Debug,
        minZ = 31.40,
        maxZ = 31.70
     }, {
        options = { 
            {
                type = 'client',
                event = 'qb-bankrobbery:client:OfficePassword',
                icon = 'fas fa-terminal',
                label = Locales['paleto_input_header'],
                canInteract = function()
                    return Shared.Banks['Paleto'].officeHacks[3].hacked
                end,
                office = 3,
            }
        },
        distance = 1.5,
    })

    -- Vault Panel
    exports['qb-target']:AddBoxZone('bankrobbery_panel_paleto', vector3(-101.86, 6462.81, 31.70), 0.6, 0.4, {
        name = 'bankrobbery_panel_paleto',
        heading = 135,
        debugPoly = Shared.Debug,
        minZ = 31.70,
        maxZ = 32.50
     }, {
        options = { 
            {
                type = 'client',
                event = 'qb-bankrobbery:client:UseBlueLaptop',
                icon = 'fas fa-user-secret',
                label = Locales['panel_target_hack'],
                canInteract = function()
                    return not Shared.Banks['Paleto'].hacked
                end
            },
            {
                type = 'server',
                event = 'qb-bankrobbery:server:PDClose',
                icon = 'fas fa-door-closed',
                label = Locales['panel_target_pd'],
                canInteract = function()
                    return Shared.Banks['Paleto'].hacked
                end,
                bank = 'Paleto',
                job = 'police'
            }
        },
        distance = 1.5,
    })

end)