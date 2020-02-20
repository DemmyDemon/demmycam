
function log (...)
    local numElements = select('#', ...)
    local elements = {...}
    local line = ''
    local prefix = '['..os.date("%H:%M:%S")..'] '
    suffix = '\n'
    local resourceName = '<'..GetCurrentResourceName()..'>'

    for i=1,numElements do
        local entry = elements[i]
        line = line..' '..tostring(entry)
    end
    Citizen.Trace(prefix..resourceName..line..suffix)
end

RegisterNetEvent('demmycam:requestcam')
AddEventHandler ('demmycam:requestcam', function()
    local src = source
    if not Config.Permission or IsPlayerAceAllowed(src, Config.Permission) then
        TriggerClientEvent('demmycam:startcam', src)
    else
        TriggerClientEvent('demmycam:nope',src)
    end
end)

RegisterNetEvent('demmycam:deletenetworked')
AddEventHandler ('demmycam:deletenetworked',function(owner, netID)
    local src = source
    if not Config.Permission or IsPlayerAceAllowed(src, Config.Permission) then
        log(src,GetPlayerName(src),'requests deletion of',netID,'belonging to',owner,GetPlayerName(owner))
        TriggerClientEvent('demmycam:delete',owner,netID)
    else
        log(src,GetPlayerName(src),'was not allowed to delete',netID,'belonging to',owner,GetPlayerName(owner))
    end
end)

RegisterNetEvent('demmycam:log')
AddEventHandler ('demmycam:log',function(...)
    log(string.format("%i %s",source, GetPlayerName(source)), ...)
end)
RegisterNetEvent('demmycam:output')
AddEventHandler ('demmycam:output', function(...)
    local numElements = select('#', ...)
    local elements = {...}
    local line
    for i=1,numElements do
        local entry = elements[i]
        if not line then
            line = tostring(entry)
        else
            line = line..' '..tostring(entry)
        end
    end
    Citizen.Trace(line..'\n')
end)