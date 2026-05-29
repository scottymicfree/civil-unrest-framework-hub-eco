RegisterNetEvent("civilUnrest:dispatchService")
AddEventHandler("civilUnrest:dispatchService", function(coords, type)
    print("[Civil Unrest | AGI-OS] Global Dispatch Signal Received via Router for Service: " .. type)
    -- Native network event sending payload to all active clients to instantiate local AI Peds.
    TriggerClientEvent("civilUnrest:forceSpawnService", -1, coords, type)
end)
