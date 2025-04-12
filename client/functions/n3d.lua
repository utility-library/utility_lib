StartN3dRenderLoop = function()
    Citizen.CreateThread(function()
        while true do
            local drawing = false

            for k,v in pairs(Utility.Cache.N3d) do
                if v.show then
                    drawing = true

                    local scaleformCoords
                    local scaleformScale
                    local rotation = vector3(0.0, 0.0, 0.0)

                    if v.advanced_scale then
                        scaleformScale = v.advanced_scale
                    else
                        scaleformScale = vector3(v.scale*1, v.scale*(9/16), 1)
                    end

                    if v.attach ~= nil then
                        local rot = v.rotation.rotation or 0.0

                        if v.rotation.syncedwithplayer then
                            rotation = vector3(0.0, 0.0, -GetEntityHeading(v.attach.entity) + rot)
                        else
                            rotation = vector3(0.0, 0.0, rot)
                        end
                        
                        local coords = GetOffsetFromEntityInWorldCoords(v.attach.entity, v.attach.offset.x, v.attach.offset.y, v.attach.offset.z)
                        
                        scaleformCoords = vector3(coords.x, coords.y, coords.z)
                    else
                        local rot = v.rotation.rotation or 0.0

                        if v.rotation.syncedwithplayer then
                            rotation = vector3(0.0, 0.0, -GetEntityHeading(PlayerPedId()) + rot)
                        else
                            rotation = vector3(0.0, 0.0, rot)
                        end
                        
                        scaleformCoords = vector3(v.coords.x, v.coords.y, v.coords.z)
                    end
                    
                    if v.scaleform ~= nil and HasScaleformMovieLoaded(v.scaleform) then
                        --                            handle           coords          rot      unk        scale      unk
                        DrawScaleformMovie_3dNonAdditive(v.scaleform, scaleformCoords, rotation, 0.0, 1.0, 0.0, scaleformScale, 0)
                    end
                end
            end

            if not drawing then
                Citizen.Wait(Config.UpdateCooldown)
            end

            Citizen.Wait(0)
        end
    end)
end