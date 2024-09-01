DrawMarkerType = function(type, v)
    if type == 0 then
        if v.text ~= "" then
            DrawText3Ds(v.coords, v.text, v._scale or 0.35, v.font or 4, v.rect or false)
        end
    elseif type == 1 then
        local dir = v._direction or {x = 0.0, y = 0.0, z = 0.0}
        local rot = v._rot or {x = 0.0, y = 0.0, z = 0.0}
        local scale = v._scale or {x = 1.5, y = 1.5, z = 0.5}

        DrawMarker(v._type or 1, v.coords, dir.x or 0.0, dir.y or 0.0, dir.z or 0.0, rot.x or 0.0, rot.y or 0.0, rot.z or 0.0, scale.x or 1.5, scale.y or 1.5, scale.z or 0.5, v.rgb[1], v.rgb[2], v.rgb[3], v.alpha or 100, v.anim or false, false, 2, false, nil, nil, v.draw_entity or false)
    end
end

EnteredMarker = function(k, v)
    Emit("entered", false, "marker", k)
    v.near = true
end

LeavedMarker = function(k, v)
    Emit("leaved", false, "marker", k)
    v.near = false
end

DrawUtilityMarker = function(k,v)        
    if v.candraw then
        local distance = #(GetEntityCoords(player) - v.coords)
        local doingSomething = false

        if distance < (v.render_distance or 0) then   
            doingSomething = true                                
            DrawMarkerType(v.type, v)
        end
        
        if distance < v.interaction_distance then
            if v.notify ~= nil then
                ButtonNotificationInternal(v.notify, not v.near)
            end

            if not v.near then
                EnteredMarker(k, v)
            end
        else
            if v.near then
                LeavedMarker(k, v)
                ClearAllHelpMessages()
            end
        end

        return doingSomething
    end
end

TryToDrawUtilityMarkers = function(slice)
    local drawing = false

    for k,v in pairs(Utility.Cache.Marker) do
        if v.slice == slice or v.slice == "ignore" then
            if DrawUtilityMarker(k,v) then
                drawing = true
            end
        end
    end

    return drawing
end

CheckIfCanView = function(jobs)
    if uPlayer then
        if type(jobs) == "table" then
            for i=1, #jobs do
                if CurrentFramework == "Utility" then
                    for j=1, #uPlayer.jobs do
                        if jobs[i] == uPlayer.jobs[j].name then
                            return true
                        end
                    end
                else
                    if jobs[i] == uPlayer.job.name then
                        return true
                    end
                end
            end
        else
            if CurrentFramework == "Utility" then
                for i=1, #uPlayer.jobs do
                    if jobs == uPlayer.jobs[i].name then
                        return true
                    end
                end
            else
                if jobs == uPlayer.job.name then
                    return true
                end 
            end
        end
    end
end

UpdateCanDraw = function(type)
    for k,v in pairs(Utility.Cache[type]) do
        if v.job then
            v.candraw = CheckIfCanView(v.job)
        else
            v.candraw = true
        end
    end
end

RefreshDrawProperties = function()
    UpdateCanDraw("Marker")
    UpdateCanDraw("Object")
    UpdateCanDraw("Dialogue")
end

JobChange = function()
    for id,data in pairs(Utility.Cache.Blips) do
        if CheckIfCanView(data.job) then
            if not data.blip then
                data.blip = CreateBlip(data.name, data.coords, data.sprite, data.colour, data.scale)
            end
        else
            if data.blip then
                RemoveBlip(data.blip)
                data.blip = nil
            end
        end
    end

    RefreshDrawProperties()
end

LoadJobsAndListenForChanges = function()
    Citizen.CreateThread(function()
        Citizen.Wait(500)
        
        if GetResourceState("es_extended") == "started" then
            CurrentFramework = "ESX"

            local ESX = exports["es_extended"]:getSharedObject()
            
            while ESX.GetPlayerData().job == nil do
                Citizen.Wait(1)
            end
            
            uPlayer = ESX.GetPlayerData()
            JobChange()
        
            RegisterNetEvent('esx:setJob', function(job)        
                uPlayer.job = job
                JobChange()
            end)
        elseif GetResourceState("qb-core") == "started" then
            CurrentFramework = "QB"

            local QBCore = exports['qb-core']:GetCoreObject()

            RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
                uPlayer = QBCore.Functions.GetPlayerData()
                JobChange()
            end)

            RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
                uPlayer.job = job
                JobChange()
            end)
        elseif GetResourceState("utility_framework") == "started" then
            CurrentFramework = "Utility"
            JobChange()
        end
    end)
end

StartMarkersRenderLoop = function()
    CreateLoop(function(loopId)
        local drawing = false

        if SliceUsed(currentSlice) then
            drawing = TryToDrawUtilityMarkers(currentSlice)
        end

        if not drawing then
            Citizen.Wait(Config.UpdateCooldown)
        end
    end)
end