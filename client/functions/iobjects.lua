StartIObjectsEnterLeaveLoop = function()
    CreateLoop(function(loopId)
        if SliceUsed(currentSlice) then
            for k,v in pairs(Utility.Cache.Object) do
                if currentSlice == v.slice then
                    local distance = #(GetEntityCoords(player) - v.coords)
                    
                    if IsOnScreen(v.coords) then
                        local caninteract = true
                        
                        if v.job then
                            caninteract = CheckIfCanView(v.job)
                        end

                        if caninteract then
                            if distance < v.interaction_distance then
                                if not v.near then
                                    Emit("entered", false, "object", k)
                                    v.near = true
                                end
                                v.near = true
                            else
                                if v.near then
                                    Emit("leaved", false, "object", k)
                                    v.near = false
                                end
                            end
                        end
                    end
                end
            end
        end
    end, Config.UpdateCooldown)
end