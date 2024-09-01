ButtonNotificationInternal = function(msg, beep) -- Skip the multigsub function for faster execution
    AddTextEntry('ButtonNotificationInternal', msg)
    BeginTextCommandDisplayHelp('ButtonNotificationInternal')
    EndTextCommandDisplayHelp(0, true, beep, -1)
end

CreateBlip = function(name, coords, sprite, colour, scale)
    local blip = AddBlipForCoord(coords)

    SetBlipSprite (blip, sprite)
    SetBlipScale  (blip, scale or 1.0)
    SetBlipColour (blip, colour)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(name)
    EndTextCommandSetBlipName(blip)
    return blip
end

StartCacheUpdateLoop = function()
    CreateLoop(function(loopId)
        currentSlice = GetSelfSlice()
        player = PlayerPedId()
    end, Config.UpdateCooldown)
end

Emit = function(type, manual, ...)
    TriggerEvent("Utility:On:".. (manual and "!" or "") ..type, ...)
end

EmitInteraction = function()
    for k,v in pairs(Utility.Cache.Marker) do
        local distance = #(GetEntityCoords(PlayerPedId()) - v.coords)

        if v.near and distance < v.interaction_distance then
            Emit("marker", false, k)
            v.near = false
        end
    end

    for k,v in pairs(Utility.Cache.Object) do
        local distance = #(GetEntityCoords(PlayerPedId()) - v.coords)	
        
        if v.near and distance < v.interaction_distance then
            Emit("object", false, k)
            v.near = false
        end
    end
end

-- It is not directly in the fxmanifest because many do not know that the utility lib can run without the utility framework
-- and keep reporting the error "Failed to load script @utility_framework/client/api.lua". 
LoadUtilityFrameworkIfFound = function()
    if GetResourceState("utility_framework") ~= "missing" then
        local init = LoadResourceFile("utility_framework", "client/api.lua")
    
        if init then
            load(init, "@utility_framework/client/api.lua")()
        end
    end
end