GlobalState.ModelsRenderDistance = {}

LoadUtilityFrameworkIfFound()

--#region Jobs handling for markers
Citizen.CreateThread(function()
    LoadJobsAndRegisterCallbacks()
    ListenForJobsChanges()
end)
--#endregion

--#region Events
RegisterServerEvent("Utility:SwapModel", function(coords, model, newmodel)
    TriggerClientEvent("Utility:SwapModel", -1, coords, model, newmodel)
end)

RegisterServerEvent("Utility:StartParticleFxOnNetworkEntity", function(...)
    TriggerClientEvent("Utility:StartParticleFxOnNetworkEntity", -1, ...)
end)

RegisterServerEvent("Utility:FreezeNoNetworkedEntity", function(...)
    TriggerClientEvent("Utility:FreezeNoNetworkedEntity", -1, ...)
end)
--#endregion

--#region UtilityNet
UtilityNet.RegisterEvents()
--#endregion