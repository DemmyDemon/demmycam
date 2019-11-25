local ACTIVE = false
local PENDING = false
local cam
local MODE = 1
local ZERO = vector3(0,0,0)
local SPEED = Config.Speed.Start

AddTextEntry('DCAMTARGETOBJECT','Model: ~a~~n~Location: ~a~~n~Heading: ~a~')
AddTextEntry('DCAMTARGETOBJECTNET', 'Model: ~a~~n~Location: ~a~~n~Heading: ~a~~n~NetOwner: ~a~ (~1~)')
AddTextEntry('DCAMMODE', 'DemmyCam Mode ~1~/~1~~n~~a~~n~Speed: ~1~%')

function log(...)
    TriggerServerEvent('demmycam:log',...)
end

function getCam()
    if not cam or not DoesCamExist(cam) then
        cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        print('Created camera '..cam)
    end
    return cam
end

function startCam()
    PENDING = false
    if not ACTIVE then
        if Config.Conceal then
            NetworkConcealPlayer(PlayerId(), true, false)
        end

        local location = GetGameplayCamCoord()
        local rot = GetGameplayCamRot(2)
        local fov = GetGameplayCamFov()

        local cam = getCam()
        RenderScriptCams(true, true, 500, true, false, false)
        SetCamCoord(cam, location)
        SetCamRot(cam, rot, 2)
        SetCamFov(cam, fov)

        log('started DemmyCam')
        ACTIVE = true
    end
end
function stopCam(teleport)
    log('ended DemmyCam')
    if ACTIVE then
        local player = PlayerId()
        if NetworkIsPlayerConcealed(player) then
            NetworkConcealPlayer(player, false, false)
        end

        if teleport then
            RenderScriptCams(false, false, 0, false, false, false)
        else
            local time = math.floor(#( GetCamCoord(cam) - GetEntityCoords(PlayerPedId())))
            RenderScriptCams(false, true, time, false, false, false)
        end
        DestroyCam(getCam(), false)
        cam = nil

        ClearFocus()
        NetworkClearVoiceProximityOverride()
    end
    ACTIVE = false
end
function disableFuckingEverything()
    for i=0, 31 do
        DisableAllControlActions(i)
    end
    for _,control in ipairs(Config.EnableInCam) do
        EnableControlAction(0, control, true)
    end
end
function getMouseMovement()
    local x = GetDisabledControlNormal(0, 2)
    local y = 0
    local z = GetDisabledControlNormal(0, 1)
    return vector3(-x, y, -z) * Config.Sensitivity
end
function getRelativeLocation(location, rotation, distance)
    location = location or vector3(0,0,0)
    rotation = rotation or vector3(0,0,0)
    distance = distance or 10.0
    
    local tZ = math.rad(rotation.z)
    local tX = math.rad(rotation.x)
    
    local absX = math.abs(math.cos(tX))

    local rx = location.x + (-math.sin(tZ) * absX) * distance
    local ry = location.y + (math.cos(tZ) * absX) * distance
    local rz = location.z + (math.sin(tX)) * distance

    return vector3(rx,ry,rz)
end
function getMovementInput(location, rotation, frameTime)
    local multiplier = 1.0
    if IsDisabledControlPressed(0, Config.Keys.Boost) then
        multiplier = Config.BoostFactor
    end

    if IsDisabledControlPressed(0, Config.Keys.Right) then
        local camRot = vector3(0,0,rotation.z)
        location = getRelativeLocation(location, camRot + vector3(0,0,-90), SPEED * frameTime * multiplier)
    elseif IsDisabledControlPressed(0, Config.Keys.Left) then
        local camRot = vector3(0,0,rotation.z)
        location = getRelativeLocation(location, camRot + vector3(0,0,90), SPEED * frameTime * multiplier)
    end

    if IsDisabledControlPressed(0, Config.Keys.Forward) then
        location = getRelativeLocation(location, rotation, SPEED * frameTime * multiplier)
    elseif IsDisabledControlPressed(0, Config.Keys.Back) then
        location = getRelativeLocation(location, rotation, -SPEED * frameTime * multiplier)
    end

    if IsDisabledControlPressed(0, Config.Keys.Up) then
        location = location + vector3(0,0,SPEED * frameTime * multiplier)
    elseif IsDisabledControlPressed(0, Config.Keys.Down) then
        location = location + vector3(0,0,-SPEED * frameTime * multiplier)
    end

    return location
end

function drawEntityBox(entity,r,g,b,a)
    if entity then

        r = r or 255
        g = g or 0
        b = b or 0
        a = a or 40

        local model = GetEntityModel(entity)
        local min,max = GetModelDimensions(model)

        local top_front_right = GetOffsetFromEntityInWorldCoords(entity,max)
        local top_back_right = GetOffsetFromEntityInWorldCoords(entity,vector3(max.x,min.y,max.z))
        local bottom_front_right = GetOffsetFromEntityInWorldCoords(entity,vector3(max.x,max.y,min.z))
        local bottom_back_right = GetOffsetFromEntityInWorldCoords(entity,vector3(max.x,min.y,min.z))

        local top_front_left = GetOffsetFromEntityInWorldCoords(entity,vector3(min.x,max.y,max.z))
        local top_back_left = GetOffsetFromEntityInWorldCoords(entity,vector3(min.x,min.y,max.z))
        local bottom_front_left = GetOffsetFromEntityInWorldCoords(entity,vector3(min.x,max.y,min.z))
        local bottom_back_left = GetOffsetFromEntityInWorldCoords(entity,min)


        -- LINES

        -- RIGHT SIDE
        DrawLine(top_front_right,top_back_right,r,g,b,a)
        DrawLine(top_front_right,bottom_front_right,r,g,b,a)
        DrawLine(bottom_front_right,bottom_back_right,r,g,b,a)
        DrawLine(top_back_right,bottom_back_right,r,g,b,a)

        -- LEFT SIDE
        DrawLine(top_front_left,top_back_left,r,g,b,a)
        DrawLine(top_back_left,bottom_back_left,r,g,b,a)
        DrawLine(top_front_left,bottom_front_left,r,g,b,a)
        DrawLine(bottom_front_left,bottom_back_left,r,g,b,a)

        -- Connection
        DrawLine(top_front_right,top_front_left,r,g,b,a)
        DrawLine(top_back_right,top_back_left,r,g,b,a)
        DrawLine(bottom_front_left,bottom_front_right,r,g,b,a)
        DrawLine(bottom_back_left,bottom_back_right,r,g,b,a)


        -- POLYGONS

        -- FRONT
        DrawPoly(top_front_left,top_front_right,bottom_front_right,r,g,b,a)
        DrawPoly(bottom_front_right,bottom_front_left,top_front_left,r,g,b,a)

        -- TOP
        DrawPoly(top_front_right,top_front_left,top_back_right,r,g,b,a)
        DrawPoly(top_front_left,top_back_left,top_back_right,r,g,b,a)

        -- BACK
        DrawPoly(top_back_right,top_back_left,bottom_back_right,r,g,b,a)
        DrawPoly(top_back_left,bottom_back_left,bottom_back_right,r,g,b,a)

        -- LEFT
        DrawPoly(top_back_left,top_front_left,bottom_front_left,r,g,b,a)
        DrawPoly(bottom_front_left,bottom_back_left,top_back_left,r,g,b,a)

        -- RIGHT
        DrawPoly(top_front_right,top_back_right,bottom_front_right,r,g,b,a)
        DrawPoly(top_back_right,bottom_back_right,bottom_front_right,r,g,b,a)

        -- BOTTOM
        DrawPoly(bottom_front_left,bottom_front_right,bottom_back_right,r,g,b,a)
        DrawPoly(bottom_back_right,bottom_back_left,bottom_front_left,r,g,b,a)

        return true

    end
    return false
end

function drawEntityInfo(entity, textLocation, networked)
    local heading = GetEntityHeading(entity)
    local model = GetEntityModel(entity)
    local location = GetEntityCoords(entity)

    SetDrawOrigin(textLocation, false)
    if networked then
        BeginTextCommandDisplayText("DCAMTARGETOBJECTNET")
    else
        BeginTextCommandDisplayText("DCAMTARGETOBJECT")
    end
    SetTextScale(0.3,0.3)
    SetTextOutline()
    AddTextComponentSubstringPlayerName(model)
    AddTextComponentSubstringPlayerName(string.format("vector3(%.2f, %.2f, %.2f)", location.x, location.y, location.z))
    AddTextComponentSubstringPlayerName(string.format("%.2f", heading))
    if networked then
        local owner = NetworkGetEntityOwner(entity)
        local name = GetPlayerName(owner)
        AddTextComponentSubstringPlayerName(name)
        AddTextComponentInteger(GetPlayerServerId(owner))
    end
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
    return model
end

local MODES = {
    {
        name = '👻 Possess',
        marker = {
            type = 28,
            offset = vector3(0,0,0),
            scale = 1.0,
            color = {255, 255, 255, 128},
        },
        entityBox = true,
        rayFlags = 7,
        click = function(location, heading, entity, networked)
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
        name = '📍 Location picker',
        marker = {
            type = 28,
            offset = vector3(0,0,0),
            scale = 0.1,
            color = {255, 0, 0, 100},
        },
        entityBox = false,
        rayFlags = 23,
        click = function(location, heading, entity, networked)
            local spec = string.format("{coords=vector3(%.3f, %.3f, %.3f),heading=%.3f},", location.x, location.y, location.z, heading)
            TriggerEvent('chat:addMessage',{args={'Location',spec}})
            log(spec)
        end,
    },
    {
        name = '🚪 Object picker',
        marker = {
            type = 43,
            offset = vector3(0,0,0),
            scale = 0.3,
            color = {255, 0, 0, 100},
        },
        entityBox = true,
        rayFlags = 17,
        click = function(location, heading, entity, networked)
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
        name = '💣 Network entity deleter',
        marker = {
            type = 42,
            offset = vector3(0,0,0),
            scale = 1.0,
            color = {255, 0, 0, 200},
        },
        entityBox = true,
        rayFlags = 23,
        click = function(location, heading, entity, networked)
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
}

function drawModeText()
    local modeName = MODES[MODE].name
    BeginTextCommandDisplayText('DCAMMODE')
    SetTextScale(0.25,0.25)
    SetTextOutline()
    SetTextCentre(true)
    AddTextComponentInteger(MODE)
    AddTextComponentInteger(#MODES)
    AddTextComponentSubstringPlayerName(modeName)
    AddTextComponentInteger(SPEED)
    EndTextCommandDisplayText(0.5, 0.1)

end

function doCamFrame()
    if ACTIVE then
        disableFuckingEverything()
        local frameTime = GetFrameTime()
        local cam = getCam()
        
        local rotation = GetCamRot(cam,2)
        rotation = rotation + getMouseMovement()
        if rotation.x > 85 then
            rotation = vector3(85, rotation.y, rotation.z)
        elseif rotation.x < -85 then
            rotation = vector3(-85, rotation.y, rotation.z)
        end
        SetCamRot(cam, rotation, 2)
        
        local location = GetCamCoord(cam)
        local newLocation = getMovementInput(location, rotation, frameTime)
        SetCamCoord(cam, newLocation)

        if IsDisabledControlJustPressed(0, Config.Keys.SwitchMode) then
            if MODE + 1 > #MODES then
                MODE = 1
            else
                MODE = MODE + 1
            end
        end
        local modeData = MODES[MODE]

        drawModeText()

        if IsDisabledControlJustPressed(0, Config.Keys.SpeedUp) then
            SPEED = SPEED + Config.Speed.Interval
            SPEED = math.min(SPEED, Config.Speed.Max)
        elseif IsDisabledControlJustPressed(0, Config.Keys.SlowDown) then
            SPEED = SPEED - Config.Speed.Interval
            SPEED = math.max(SPEED, Config.Speed.Min)
        end

        local targetLocation = getRelativeLocation(location, rotation, 100)
        local ray = StartShapeTestRay(newLocation, targetLocation, modeData.rayFlags, 0)
        local someInt,hit,hitCoords,normal,entity = GetShapeTestResult(ray)

        local continue = true

        if hit then

            if not DoesEntityExist(entity) then
                entity = nil
            elseif not IsEntityAnObject(entity) and not IsEntityAPed(entity) and not IsEntityAVehicle(entity) then
                entity = nil
            end
            
            local r = 255
            local g = 0
            local b = 0
            local a = 40
            local networked = false

            if entity and NetworkGetEntityIsNetworked(entity) then
                if NetworkGetEntityOwner(entity) == PlayerId() then
                    r = 0
                    g = 255
                else
                    r = 255
                    g = 255
                end
                networked = true
            end

            if modeData.click and IsDisabledControlJustPressed(0, 24) then
                modeData.click(hitCoords, rotation.z, entity, networked)
            end

            if ACTIVE then -- It could have changed during click!

                if entity and modeData.entityBox and drawEntityBox(entity, r, g, b, a) then
                    local model = drawEntityInfo(entity, hitCoords, networked)
                else
                    DrawMarker(
                        modeData.marker.type, -- Type
                        hitCoords + modeData.marker.offset,
                        0.0, 0.0, 0.0, -- Direction
                        0.0, 0.0, rotation.z, -- Rotation
                        modeData.marker.scale, modeData.marker.scale, modeData.marker.scale,
                        modeData.marker.color[1], modeData.marker.color[2], modeData.marker.color[3], modeData.marker.color[4],
                        false, -- bobs
                        false, -- face camera
                        2, -- Cargo Cult
                        false, -- rotates
                        0, 0, -- texture
                        false -- projects on entities
                    )
                    if IsDisabledControlJustPressed(0, Config.Keys.Teleport) then
                        if #(hitCoords - ZERO) > 0.25 then
                            stopCam(true)
                            Citizen.Wait(0)
                            local playerPed = PlayerPedId()
                            SetEntityCoords(playerPed, hitCoords, false, false, false, true)
                            SetEntityHeading(playerPed, rotation.z)
                            SetGameplayCamRelativeHeading(0.0)
                            SetGameplayCamRelativePitch(rotation.x, 1.0)
                        end
                    end
                end
            end
        end

        if ACTIVE then -- because click might have deactivated
            SetFocusArea(location, ZERO)
            NetworkApplyVoiceProximityOverride(location)
        end
    end
end

Citizen.CreateThread(function()
    local ready = false
    while true do
        if ready then
            if not Config.UseModifier then
                DisableControlAction(1, Config.Keys.Toggle)
            end
            if not IsPauseMenuActive() then
                if not PENDING then
                    if not Config.UseModifier or IsDisabledControlPressed(0, Config.Keys.Modifier) then
                        if IsDisabledControlJustPressed(0, Config.Keys.Toggle) then
                            if ACTIVE then
                                stopCam()
                            else
                                PENDING = true
                                TriggerServerEvent('demmycam:requestcam')
                            end
                        end
                    end
                end
                doCamFrame()
            end
            Citizen.Wait(0)
        else
            if NetworkIsSessionStarted() then
                ready = true
            else
                Citizen.Wait(100)
            end
        end
    end
end)

RegisterNetEvent('demmycam:nope')
AddEventHandler ('demmycam:nope', function()
    Citizen.CreateThread(function()
        Citizen.Wait(5000)
        PENDING = false
    end)
end)

RegisterNetEvent('demmycam:startcam')
AddEventHandler ('demmycam:startcam', function()
    startCam()
end)

RegisterNetEvent('demmycam:delete')
AddEventHandler ('demmycam:delete', function(netID)
    local entity = NetworkGetEntityFromNetworkId(netID)
    if entity and DoesEntityExist(entity) and NetworkHasControlOfEntity(entity) then
        SetEntityAsMissionEntity(entity)
        DeleteEntity(entity)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        stopCam()
    end
end)