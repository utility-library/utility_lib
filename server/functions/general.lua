-- It is not directly in the fxmanifest because many do not know that the utility lib can run without the utility framework
-- and keep reporting the error "Failed to load script @utility_framework/client/api.lua". 
LoadUtilityFrameworkIfFound = function()
    if GetResourceState("utility_framework") ~= "missing" then
        local init = LoadResourceFile("utility_framework", "server/api.lua")
    
        if init then
            load(init, "@utility_framework/server/api.lua")()
        end
    end
end