MODES = {
    {
        name = 'Possess',
        symbol = '👻',
        marker = {
            type = 28,
            offset = vector3(0,0,0),
            scale = 1.0,
            color = {255, 255, 255, 128},
        },
        entityBox = true,
        rayFlags = 7,
        click = function(location, heading, entity, networked, normal, modeData)
            if entity then
                if IsEntityAPed(entity) and not IsPedAPlayer(entity) then
                    stopCam(true)
                    ChangePlayerPed(PlayerId(), entity, true, true)
                elseif IsEntityAVehicle(entity) then
                    local driver = GetPedInVehicleSeat(entity, -1)
                    if IsEntityAPed(driver) and not IsPedAPlayer(driver) then
                        stopCam(true)
                        ChangePlayerPed(PlayerId(), driver, true, true)
                    end
                end
            end
        end,
    },
    {
        name = 'Location picker',
        symbol = '📍',
        marker = {
            type = 28,
            offset = vector3(0,0,0),
            scale = 0.1,
            color = {255, 0, 0, 100},
        },
        entityBox = false,
        rayFlags = 23,
        click = function(location, heading, entity, networked, normal, modeData)
            local spec = string.format("{coords=vector3(%.3f, %.3f, %.3f),heading=%.3f},", location.x, location.y, location.z, heading)
            TriggerEvent('chat:addMessage',{args={'Location',spec}})
            log(spec)
        end,
    },
    {
        name = 'Camera location',
        symbol = '🎥',
        marker = {
            type = 28,
            offset = vector3(0,0,0),
            scale = 0.1,
            color = {255, 255, 0, 100},
        },
        entityBox = false,
        rayFlags = 23,
        click = function()
            local rotation = GetFinalRenderedCamRot(2)
            local location = GetFinalRenderedCamCoord()
            local spec = string.format("{coords=vector3(%.3f,%.3f,%.3f),rot=vector3(%.3f,%.3f,%.3f)}", location.x, location.y, location.z, rotation.x, rotation.y, rotation.z)
            TriggerEvent('chat:addMessage',{args={'CamLocation',spec}})
            log(spec)
        end,
    },
    {
        name = 'Wall lock panel placement',
        symbol = '🔒',
        object = {
            --model = `ba_prop_battle_secpanel`,
            --model = `v_res_tre_alarmbox`,
            --model = `prop_wall_light_08a`,
            --model = `v_ilev_chopshopswitch`,
            model = `prop_ld_keypad_01`,
        },
        init = function(modeData)
            if modeData.object.model and IsModelValid(modeData.object.model) then
                if not HasModelLoaded(modeData.object.model) then
                    RequestModel(modeData.object.model)
                    local begin = GetGameTimer()
                    while not HasModelLoaded(modeData.object.model) and GetGameTimer() <= begin + (modeData.object.timeout or 5000) do
                        Citizen.Wait(100)
                    end
                end
                if HasModelLoaded(modeData.object.model) then
                    modeData.object.handle = CreateObject(modeData.object.model, hitCoords, false, false, false)
                    --SetObjectAsNoLongerNeeded(modeData.object.handle)
                    SetModelAsNoLongerNeeded(modeData.object.model)
                    SetEntityCollision(modeData.object.handle, false, false)
                    modeData.ignore = modeData.object.handle
                else
                    TriggerEvent('chat:addMessage',{args={'ERROR','Failed to load model'}})
                end
            end
        end,
        cleanup = function(modeData)
            if modeData.object.handle and DoesEntityExist(modeData.object.handle) then
                SetEntityAsMissionEntity(modeData.object.handle)
                DeleteEntity(modeData.object.handle)
                modeData.object.handle = nil
                modeData.ignore = nil
            end
        end,
        entityBox = false,
        rayFlags = 23,
        click = function(location, heading, entity, networked, normal, modeData)
            if modeData.object and modeData.object.handle then
                local handle = modeData.object.handle
                local location = GetEntityCoords(handle)
                local normal = GetEntityRotation(handle, 2)
                local spec = string.format("{coords=vector3(%.3f, %.3f, %.3f),rot=vector3(%.3f, %.3f, %.3f)},", location.x, location.y, location.z, normal.x, normal.y, normal.z)
                TriggerEvent('chat:addMessage',{args={'Location',spec}})
                log(spec)
            end
        end,
    },
    {
        name = 'Door lock panel placement',
        symbol = '🔒🚪',
        object = {
            --model = `ba_prop_battle_secpanel`,
            --model = `v_res_tre_alarmbox`,
            --model = `prop_wall_light_08a`,
            --model = `v_ilev_chopshopswitch`,
            model = `prop_ld_keypad_01`,
        },
        init = function(modeData)
            if modeData.object.model and IsModelValid(modeData.object.model) then
                if not HasModelLoaded(modeData.object.model) then
                    RequestModel(modeData.object.model)
                    local begin = GetGameTimer()
                    while not HasModelLoaded(modeData.object.model) and GetGameTimer() <= begin + (modeData.object.timeout or 5000) do
                        Citizen.Wait(100)
                    end
                end
                if HasModelLoaded(modeData.object.model) then
                    modeData.object.handle = CreateObject(modeData.object.model, hitCoords, false, false, false)
                    --SetObjectAsNoLongerNeeded(modeData.object.handle)
                    SetModelAsNoLongerNeeded(modeData.object.model)
                    SetEntityCollision(modeData.object.handle, false, false)
                    modeData.ignore = modeData.object.handle
                else
                    TriggerEvent('chat:addMessage',{args={'ERROR','Failed to load model'}})
                end
            end
        end,
        cleanup = function(modeData)
            if modeData.object.handle and DoesEntityExist(modeData.object.handle) then
                SetEntityAsMissionEntity(modeData.object.handle)
                DeleteEntity(modeData.object.handle)
                modeData.object.handle = nil
                modeData.ignore = nil
            end
        end,
        entityBox = true,
        rayFlags = 23,
        click = function(location, heading, entity, networked, normal, modeData)
            if entity and modeData.object and modeData.object.handle then
                
                local handle = modeData.object.handle
                local keypadLocation = GetEntityCoords(handle)
                local keypadRotation = GetEntityRotation(handle, 2)
                
                local doorLocation = GetEntityCoords(entity)
                local doorRotation = GetEntityRotation(entity, 2)

                local offsetLocation = GetOffsetFromEntityGivenWorldCoords(entity, keypadLocation)
                local offsetRotation = keypadRotation - doorRotation

                local spec = string.format(
                    "{door=?,offset=vector3(%.3f, %.3f, %.3f),rot=vector3(%.3f, %.3f, %.3f)},",
                    offsetLocation.x, offsetLocation.y, offsetLocation.z, offsetRotation.x, offsetRotation.y, offsetRotation.z
                )

                TriggerEvent('chat:addMessage',{args={'Location',spec}})
                log(spec)
            end
        end,
    },
    {
        name = 'Object picker',
        symbol = '🚪',
        marker = {
            type = 43,
            offset = vector3(0,0,0),
            scale = 0.3,
            color = {255, 0, 0, 100},
        },
        entityBox = true,
        rayFlags = 17,
        click = function(location, heading, entity, networked, normal, modeData)
            if entity then
                local heading = GetEntityHeading(entity)
                local model = GetEntityModel(entity)
                local location = GetEntityCoords(entity)
                local spec = string.format("{model=%i,coords=vector3(%.3f, %.3f, %.3f),heading=%.3f},", model, location.x, location.y, location.z, heading)
                TriggerEvent('chat:addMessage',{args={'Object',spec}})
                log(spec)
            end
        end,
    },
    {
        name = 'Network entity deleter',
        symbol = '💣',
        marker = {
            type = 42,
            offset = vector3(0,0,0),
            scale = 1.0,
            color = {255, 0, 0, 200},
        },
        entityBox = true,
        rayFlags = 23,
        click = function(location, heading, entity, networked, normal, modeData)
            if entity then
                if networked then
                    if not IsEntityAPed(entity) or not IsPedAPlayer(entity) then
                        local owner = GetPlayerServerId(NetworkGetEntityOwner(entity))
                        TriggerServerEvent('demmycam:deletenetworked', owner, NetworkGetNetworkIdFromEntity(entity))
                    end
                end
            end
        end,
    },
    {
        name = 'Local entity deleter',
        symbol = '💣',
        marker = {
            type = 42,
            offset = vector3(0,0,0),
            scale = 1.0,
            color = {255, 0, 0, 200},
        },
        entityBox = true,
        rayFlags = 23,
        click = function(location, heading, entity, networked, normal, modeData)
            if entity then
                if not networked then
                    if not IsEntityAPed(entity) or not IsPedAPlayer(entity) then
                        SetEntityAsMissionEntity(entity, true, true)
                        DeleteEntity(entity)
                    end
                end
            end
        end,
    },
}
