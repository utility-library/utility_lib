player = PlayerPedId()
LocalEntities = {} -- UtilityNet

LoadUtilityFrameworkIfFound()
LoadJobsAndListenForChanges()

--#region Loops
    StartCacheUpdateLoop()
    StartMarkersRenderLoop()
    StartIObjectsEnterLeaveLoop()
    
    StartDialoguesDrawingLoop()
    StartN3dRenderLoop()

    StartUtilityNetRenderLoop()
--#endregion
    
--#region Interaction
    IsControlJustPressed("E", EmitInteraction)
    IsControlJustPressed("LRIGHT_INDEX", EmitInteraction)

    RegisterCommand('utility', function(_, args)
        if args[1] and args[2] then
            TriggerEvent("Utility:Pressed_"..args[1].."_"..args[2])
        end
    end, true)
--#endregion

--#region Events
    RegisterNetEvent("Utility:SwapModel", function(coords, model, newmodel)
        RequestModel(newmodel)

        while not HasModelLoaded(newmodel) do
            Citizen.Wait(1)
        end

        CreateModelSwap(coords, 0.7, model, newmodel)
    end)

    RegisterNetEvent("Utility:StartParticleFxOnNetworkEntity", function(ptxAsset, name, obj, ...)
        RequestNamedPtfxAsset(ptxAsset)

        while not HasNamedPtfxAssetLoaded(ptxAsset) do
            Citizen.Wait(1)
        end

        SetPtfxAssetNextCall(ptxAsset)
        --print(name, obj, NetToObj(obj), GetEntityModel(NetToObj(obj)))
        StartNetworkedParticleFxLoopedOnEntity(name, NetToObj(obj), ...)
    end)

    RegisterNetEvent("Utility:FreezeNoNetworkedEntity", function(coords, model)
        local obj = GetClosestObjectOfType(coords, 3.0, model)

        if obj > 0 then
            FreezeEntityPosition(obj, true)
        end
    end)

    RegisterNetEvent("Utility:Create", function(type, id, table, res)
        if table.slice then
            SetSliceUsed(table.slice, true)
        end

        if table.job then
            table.candraw = CheckIfCanView(table.job)
        else
            table.candraw = true
        end

        Utility.Cache[type][id] = table 

        if type == "Blips" then
            JobChange()
        end
    end)

    RegisterNetEvent("Utility:Edit", function(type, id, field, new_data)
        if field == "slice" then
            -- Update used slice groups
            local oldSlice = Utility.Cache[type][id][field]
            local canClearOldSlice = true

            for k,v in pairs(Utility.Cache[type]) do
                if v.slice == oldSlice then
                    canClearOldSlice = false
                    break
                end
            end

            if canClearOldSlice then
                SetSliceUsed(oldSlice, false)
            end
            
            SetSliceUsed(new_data, true)
        end

        Utility.Cache[type][id][field] = new_data 
    end)

    RegisterNetEvent("Utility:Remove", function(type, id)
        Utility.Cache[type][id] = nil 
    end)

    RegisterNetEvent("Utility:FakeTrigger", function(type, id)
        Emit(type, true, id)
    end)

    if Config.EmitterTriggerForSyncedVariable then
        RegisterNetEvent("Utility:SyncValue_emit", function(name, old_value, value)
            Emit(name, false, value)
        end)
    end
--#endregion