CivilUnrestServerState = {
    isRiotActive = false
}

CivilUnrestConnectedClients = {}

RegisterNetEvent("civilUnrest:playerConnected")
AddEventHandler("civilUnrest:playerConnected", function()
    local src = source
    if not CivilUnrestConnectedClients[src] then
        CivilUnrestConnectedClients[src] = { streetCredit = 0, factionLoyalty = {} }
        print("[Civil Unrest | AGI-OS] Handshake complete for client ID: " .. src)
        TriggerClientEvent("civilUnrest:syncLoyalty", src, CivilUnrestConnectedClients[src].factionLoyalty)
    end
end)

RegisterNetEvent("civilUnrest:processCrimeCredit")
AddEventHandler("civilUnrest:processCrimeCredit", function(amount, locationCoords)
    local src = source
    if CivilUnrestConnectedClients[src] then
        CivilUnrestConnectedClients[src].streetCredit = CivilUnrestConnectedClients[src].streetCredit + amount
        
        -- Direct native notification bridge
        TriggerClientEvent("chat:addMessage", src, {
            color = {200, 0, 0},
            multiline = true,
            args = {"SYSTEM", "+ " .. amount .. " Street Credit Gained."}
        })

        -- Assess intelligence threshold for media dispatch
        if amount >= CivilUnrest.NewsVanCreditTrigger then
            print("[Civil Unrest | AGI-OS] Violence threshold met. Dispatching AI News Models.")
            TriggerClientEvent("civilUnrest:spawnNewsEvent", -1, locationCoords, "violence")
        end
    end
end)

-- One-of-a-kind Weekly Riot Scheduler Process
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000 * 60 * 60) -- Validating every hr
        local sysTime = os.date("*t")
        if sysTime.wday == CivilUnrest.RiotDayOfWeek and sysTime.hour == 21 then
            CivilUnrestServerState.isRiotActive = true
            print("[Civil Unrest | AGI-OS] Time criteria met. Dispensing Riot logic to all active local clients.")
            TriggerClientEvent("civilUnrest:startRiot", -1)
            TriggerClientEvent("civilUnrest:spawnNewsEvent", -1, vector3(0.0, 0.0, 0.0), "riot_coverage")
        end
    end
end)

RegisterNetEvent("civilUnrest:reportHighProfileCrime")
AddEventHandler("civilUnrest:reportHighProfileCrime", function(coords)
    -- Debounce logic left assumed for local scopes, natively dispatched instantly
    print("[Civil Unrest | AGI-OS] High Crime Intensity detected by local client. Media instructed.")
    TriggerClientEvent("civilUnrest:spawnNewsEvent", -1, coords, "crime_scene")
end)

-- Random Media Patrols checking out Gang Zones natively
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000 * 60 * 15) -- Every 15 mins check for interview ops
        local hasClients = false
        for k, v in pairs(CivilUnrestConnectedClients) do hasClients = true; break end
        if hasClients then
            local randomZone = CivilUnrest.GangZones[math.random(#CivilUnrest.GangZones)]
            print("[Civil Unrest | AGI-OS] Dispatching Weazel News to investigate gang activity at " .. randomZone.name)
            TriggerClientEvent("civilUnrest:spawnNewsEvent", -1, randomZone.coords, "interview")
        end
    end
end)

RegisterNetEvent("civilUnrest:serverZoneEntry")
AddEventHandler("civilUnrest:serverZoneEntry", function(zoneName)
    local src = source
    local credit = CivilUnrestConnectedClients[src] and CivilUnrestConnectedClients[src].streetCredit or 0
    local loyalty = CivilUnrestConnectedClients[src] and CivilUnrestConnectedClients[src].factionLoyalty[zoneName] or 0
    
    local zoneData = nil
    for _, z in ipairs(CivilUnrest.GangZones) do
        if z.name == zoneName then 
            zoneData = z 
            break 
        end
    end
    
    if zoneData then
        -- AGI-OS Logic constraint: High street credit yields dynamic native missions, low credit yields violent native attacks.
        -- Loyalty aggressively augments these probabilities.
        local attackChance = 30
        if loyalty < -40 then attackChance = 80 end
        if loyalty > 50 then attackChance = 5 end
        
        if math.random(1, 100) > (100 - (attackChance + 40)) then -- Threshold to trigger *something*
            local encounterType = "mission"
            
            if loyalty < -20 and math.random(1, 100) <= attackChance then
                encounterType = "hostile"
            elseif credit < 500 and math.random(1, 100) > 40 and loyalty <= 0 then
                encounterType = "hostile"
            end
            
            TriggerClientEvent("civilUnrest:triggerZoneEncounter", src, zoneData, encounterType)
            print("[Civil Unrest | AGI-OS] Evaluated zone context parameters for " .. zoneName .. " (Loyalty: " .. loyalty .. "). Executed logic: " .. encounterType)
        end
    end
end)
