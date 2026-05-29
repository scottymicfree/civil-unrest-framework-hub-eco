RegisterNetEvent("civilUnrest:updateLoyalty")
AddEventHandler("civilUnrest:updateLoyalty", function(gangName, amount)
    local src = source
    if not CivilUnrestConnectedClients[src] then return end
    
    if not CivilUnrestConnectedClients[src].factionLoyalty then
        CivilUnrestConnectedClients[src].factionLoyalty = {}
    end
    
    local current = CivilUnrestConnectedClients[src].factionLoyalty[gangName] or 0
    local newLoyalty = math.max(-100, math.min(100, current + amount))
    CivilUnrestConnectedClients[src].factionLoyalty[gangName] = newLoyalty
    
    TriggerClientEvent("civilUnrest:syncLoyalty", src, CivilUnrestConnectedClients[src].factionLoyalty)
    
    -- Sync chat overlay natively to notify player
    local color = amount > 0 and {0, 200, 0} or {200, 0, 0}
    local sign = amount > 0 and "+" or ""
    TriggerClientEvent("chat:addMessage", src, {
        color = color,
        multiline = true,
        args = {"SYSTEM", "Your loyalty with " .. gangName .. " shifted by " .. sign .. amount .. ". (Current: " .. newLoyalty .. ")"}
    })
    
    print("[Civil Unrest | AGI-OS] Client " .. src .. " loyalty for " .. gangName .. " changed to " .. newLoyalty)
end)

RegisterNetEvent("civilUnrest:registerCompanion")
AddEventHandler("civilUnrest:registerCompanion", function(name, modelType)
    local src = source
    if not CivilUnrestConnectedClients[src] then return end
    
    CivilUnrestConnectedClients[src].activeCompanion = {
        name = name,
        model = modelType,
        bondedTime = os.time()
    }
    
    print("[Civil Unrest | AGI-OS] Persistent tracking updated. Client " .. src .. " registered companion alias: " .. name)
end)
