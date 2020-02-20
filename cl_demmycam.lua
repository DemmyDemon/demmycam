local ACTIVE = false
local PENDING = false
local cam
local MODE = 1
local ZERO = vector3(0,0,0)
local SPEED = Config.Speed.Start
local EXTRA = ""
local modeButtons = PickOne:new()

AddTextEntry('DCAMTARGETOBJECT','Model: ~a~~n~Location: ~a~~n~Heading: ~a~')
AddTextEntry('DCAMTARGETOBJECTNET', 'Model: ~a~~n~Location: ~a~~n~Heading: ~a~~n~NetOwner: ~a~ (~1~)')
AddTextEntry('DCAMMODE', 'DemmyCam Mode ~1~/~1~~n~~a~~n~Speed: ~1~%~n~~a~')

function log(...)
    TriggerServerEvent('demmycam:log',...)
end
function out(...)
    TriggerServerEvent('demmycam:output', ...)
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

        if MODES[MODE].init then
            MODES[MODE].init(MODES[MODE])
        end

        log('started DemmyCam')
        ACTIVE = true
    end
end
function stopCam(teleport)
    if ACTIVE then
        log('ended DemmyCam')
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

        if MODES[MODE].cleanup then
            MODES[MODE].cleanup(MODES[MODE])
        end

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
function normalToRotation(normal, refRotation)
    --[[ Quat getRotationQuat(const Vector& from, const Vector& to){
        Quat result;
        Vector H = VecAdd(from, to);
        H = VecNormalize(H);
        result.w = VecDot(from, H);
        result.x = from.y*H.z - from.z*H.y;
        result.y = from.z*H.x - from.x*H.z;
        result.z = from.x*H.y - from.y*H.x;
        return result;
    }
    --]]
    return quat(refRotation, normal)
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

function drawModeText()
    local modeName = MODES[MODE].name
    if MODES[MODE].symbol then
        modeName = MODES[MODE].symbol..' '..modeName
    end
    BeginTextCommandDisplayText('DCAMMODE')
    SetTextScale(0.25,0.25)
    SetTextOutline()
    SetTextCentre(true)
    AddTextComponentInteger(MODE)
    AddTextComponentInteger(#MODES)
    AddTextComponentSubstringPlayerName(modeName)
    AddTextComponentInteger(SPEED)
    AddTextComponentSubstringPlayerName(EXTRA or "")
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
            local newMode = modeButtons:pick()
            if newMode and newMode ~= MODE then

                if MODES[MODE].cleanup then
                    MODES[MODE].cleanup(MODES[MODE])
                end

                MODE = newMode

                if MODES[MODE].init then
                    MODES[MODE].init(MODES[MODE])
                end

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
        local ray = StartShapeTestRay(newLocation, targetLocation, modeData.rayFlags, modeData.ignore or 0)
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
                modeData.click(hitCoords, rotation.z, entity, networked, normal, modeData)
            end

            if ACTIVE then -- It could have changed during click!

                if entity and modeData.entityBox and drawEntityBox(entity, r, g, b, a) then
                    local model = drawEntityInfo(entity, hitCoords, networked)
                end

                if modeData.marker then
                    local markerLocation = hitCoords
                    if modeData.marker.offset then
                        markerLocation = markerLocation + modeData.marker.offset
                    end
                    local markerRotation = vector3(0,0,rotation.z)
                    if modeData.marker.rotation then
                        markerRotation = vector3(modeData.marker.rotation.x, modeData.marker.rotation.y + rotation.z, modeData.marker.rotation.z)
                    end
                    DrawMarker(
                        modeData.marker.type, -- Type
                        hitCoords + modeData.marker.offset,
                        0.0, 0.0, 0.0, -- Direction
                        markerRotation.x,
                        markerRotation.y,
                        markerRotation.z,
                        modeData.marker.scale, modeData.marker.scale, modeData.marker.scale,
                        modeData.marker.color[1], modeData.marker.color[2], modeData.marker.color[3], modeData.marker.color[4],
                        false, -- bobs
                        false, -- face camera
                        1, -- Cargo Cult (Rotation order?)
                        false, -- rotates
                        0, 0, -- texture
                        false -- projects on entities
                    )
                end
                if modeData.object then
                    if modeData.object.handle and DoesEntityExist(modeData.object.handle) then
                        SetEntityCoordsNoOffset(modeData.object.handle, hitCoords, false, false, false)

                        local rotation = quat(vector3(0,-3,0), normal)
                        -- SetEntityHeading(modeData.object.handle, rotation.z)
                        SetEntityQuaternion(modeData.object.handle, rotation)

                    end
                end
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
                for index, data in ipairs(MODES) do
                    modeButtons:addButton({
                        label = data.name,
                        value = index,
                    })
                end
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