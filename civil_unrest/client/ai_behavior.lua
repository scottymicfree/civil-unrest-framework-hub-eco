-- AGI-OS Native AI Decision Making Engine
local factions = {}

Citizen.CreateThread(function()
    -- Initialize Native Relationship Groups
    for _, gang in ipairs(CivilUnrest.GangZones) do
        local hash = GetHashKey("GANG_" .. gang.name)
        AddRelationshipGroup("GANG_" .. gang.name, hash)
        factions[gang.name] = hash
        
        -- Default: Gangs are hostile to Law Enforcement natively
        SetRelationshipBetweenGroups(5, hash, GetHashKey("COP"))
        SetRelationshipBetweenGroups(5, GetHashKey("COP"), hash)
    end
    
    -- Explicit dynamic rivalries (e.g. Ballas vs Families natively)
    if factions["Ballas"] and factions["Families"] then
        SetRelationshipBetweenGroups(5, factions["Ballas"], factions["Families"])
        SetRelationshipBetweenGroups(5, factions["Families"], factions["Ballas"])
    end
    if factions["Vagos"] and factions["Marabunta Grande"] then
        SetRelationshipBetweenGroups(5, factions["Vagos"], factions["Marabunta Grande"])
        SetRelationshipBetweenGroups(5, factions["Marabunta Grande"], factions["Vagos"])
    end
    
    print("[Civil Unrest | AGI-OS] Faction matrix synchronized natively in engine.")
end)

-- Combat Analysis, Strategic Retreat, & Reputation Reactions
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2500) -- Evaluate battlefields periodically
        
        local peds = GetGamePool('CPed')
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        local lawRep = LocalPlayerLoyalty["LAW"] or 0
        local civRep = LocalPlayerLoyalty["CIVILIAN"] or 0
        
        for _, ped in ipairs(peds) do
            if not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped, 1) then
                local pedModel = GetEntityModel(ped)
                local pedFaction = GetPedFaction and GetPedFaction(pedModel) or "CIVILIAN"
                
                -- Reputation Hooks
                if not IsPedInCombat(ped, 0) and not IsPedFleeing(ped) then
                    local dist = #(GetEntityCoords(ped) - playerCoords)
                    if pedFaction == "LAW" and lawRep < -60 and dist < 25.0 then
                        -- Proactive Law Enforcement Engagement at sight due to negative rep
                        TaskCombatPed(ped, playerPed, 0, 16)
                    elseif pedFaction == "CIVILIAN" and civRep < -50 and dist < 20.0 then
                        -- Civilians scatter at player presence on bad rep
                        TaskSmartFleePed(ped, playerPed, 100.0, -1, false, false)
                    end
                end
                
                -- Check if Ped is natively in combat
                local target = GetPedTargetFromCombatPed(ped, 1)
                if target ~= 0 or IsPedInCombat(ped, 0) then
                    local health = GetEntityHealth(ped)
                    local maxHealth = GetEntityMaxHealth(ped)
                    
                    -- Strategic Retreat: If HP is below 30%, drop tasks and run away
                    if health < (maxHealth * 0.3) then
                        ClearPedTasks(ped)
                        -- 100.0 is the flee distance standard
                        TaskSmartFleePed(ped, playerPed, 100.0, -1, false, false)
                    end
                end
            end
        end
    end
end)

-- Companion Advanced Combat Logic, Threat Prioritization & Special Abilities
Citizen.CreateThread(function()
    local companionLastPed = nil
    local companionCooldowns = { smoke = 0, adrenaline = 0, suppress = 0 }

    while true do
        Citizen.Wait(1500)
        -- Validate Global Companion pointer
        if ActiveCompanionPed and DoesEntityExist(ActiveCompanionPed) and not IsEntityDead(ActiveCompanionPed) then
            if ActiveCompanionPed ~= companionLastPed then
                companionLastPed = ActiveCompanionPed
                companionCooldowns = { smoke = 0, adrenaline = 0, suppress = 0 }
            end
            
            local playerPed = PlayerPedId()

            if IsPedInCombat(ActiveCompanionPed, 0) or IsPedShooting(playerPed) then
                local peds = GetGamePool('CPed')
                local highestThreat = nil
                local highestScore = -1
                local compCoords = GetEntityCoords(ActiveCompanionPed)
                local compHealth = GetEntityHealth(ActiveCompanionPed)
                local compMaxHealth = GetEntityMaxHealth(ActiveCompanionPed)
                
                for _, ped in ipairs(peds) do
                    if ped ~= ActiveCompanionPed and ped ~= playerPed and not IsEntityDead(ped) then
                        local rel = GetRelationshipBetweenPeds(ActiveCompanionPed, ped)
                        if rel == 4 or rel == 5 or IsPedCombatTarget(ped, ActiveCompanionPed) or IsPedCombatTarget(ped, playerPed) then
                            local dist = #(compCoords - GetEntityCoords(ped))
                            local score = 0
                            
                            if dist < 60.0 then
                                score = score + (60 - dist)
                                if IsPedArmed(ped, 4) then score = score + 30 end -- High threat if armed
                                if IsPedShooting(ped) then score = score + 50 end -- Critical threat if actively firing
                                if GetEntityHealth(ped) < 100 then score = score + 10 end -- Weak targets prioritized
                                
                                if score > highestScore then
                                    highestScore = score
                                    highestThreat = ped
                                end
                            end
                        end
                    end
                end
                
                if highestThreat and highestScore > 0 then
                    -- Dynamic Weapon Acquisition & Usage
                    if CompanionArmory then
                        local dist = #(compCoords - GetEntityCoords(highestThreat))
                        local bestWeapon = nil
                        local bestWeaponScore = -100

                        for wepHash, active in pairs(CompanionArmory) do
                            if active and HasPedGotWeapon(ActiveCompanionPed, wepHash, false) then
                                local wepGroup = GetWeapontypeGroup(wepHash)
                                local wScore = 0
                                
                                if dist < 15.0 then
                                    if wepGroup == GetHashKey("GROUP_SHOTGUN") then wScore = 50
                                    elseif wepGroup == GetHashKey("GROUP_SMG") then wScore = 30
                                    elseif wepGroup == GetHashKey("GROUP_MELEE") then wScore = 20 end
                                elseif dist < 40.0 then
                                    if wepGroup == GetHashKey("GROUP_ASSAULTRIFLE") then wScore = 50
                                    elseif wepGroup == GetHashKey("GROUP_SMG") then wScore = 40
                                    elseif wepGroup == GetHashKey("GROUP_MG") then wScore = 45 end
                                else
                                    if wepGroup == GetHashKey("GROUP_SNIPER") then wScore = 50
                                    elseif wepGroup == GetHashKey("GROUP_ASSAULTRIFLE") then wScore = 40
                                    elseif wepGroup == GetHashKey("GROUP_HEAVY") then wScore = 45 end
                                end
                                
                                if wScore == 0 then wScore = 10 end
                                
                                if wScore > bestWeaponScore then
                                    bestWeaponScore = wScore
                                    bestWeapon = wepHash
                                end
                            end
                        end
                        
                        if bestWeapon and GetSelectedPedWeapon(ActiveCompanionPed) ~= bestWeapon then
                            SetCurrentPedWeapon(ActiveCompanionPed, bestWeapon, true)
                            print("[Civil Unrest | AGI-OS] AI Companion dynamically shifting to tactical weapon: " .. tostring(bestWeapon))
                        end
                    end

                    local currentTarget = GetPedTargetFromCombatPed(ActiveCompanionPed, 1)
                    if currentTarget ~= highestThreat then
                        -- Engine Override: Force companion to break current target and focus on Threat Level priority natively
                        TaskCombatPed(ActiveCompanionPed, highestThreat, 0, 16)
                    end
                    
                    -- SPECIAL ABILITY: Concentrated Suppression
                    if highestScore > 70 and GetGameTimer() - companionCooldowns.suppress > 30000 then
                        companionCooldowns.suppress = GetGameTimer()
                        TaskShootAtEntity(ActiveCompanionPed, highestThreat, 5000, 7) -- 7 = FiringPattern.FullAuto
                        print("[Civil Unrest | AGI-OS] AI Companion deployed Concentrated Suppression natively.")
                    end
                    
                    -- SPECIAL ABILITY: Adrenaline Rush
                    if highestScore > 90 and GetGameTimer() - companionCooldowns.adrenaline > 60000 then
                        companionCooldowns.adrenaline = GetGameTimer()
                        SetPedAccuracy(ActiveCompanionPed, 100)
                        SetPedShootRate(ActiveCompanionPed, 200)
                        print("[Civil Unrest | AGI-OS] AI Companion activated Offensive Adrenaline Rush.")
                        Citizen.CreateThread(function()
                            Citizen.Wait(15000)
                            if ActiveCompanionPed and DoesEntityExist(ActiveCompanionPed) then
                                SetPedAccuracy(ActiveCompanionPed, 60)
                                SetPedShootRate(ActiveCompanionPed, 100)
                            end
                        end)
                    end
                end
                
                -- SPECIAL ABILITY: Defensive Smoke Screen
                if compHealth < (compMaxHealth * 0.4) and GetGameTimer() - companionCooldowns.smoke > 45000 then
                    companionCooldowns.smoke = GetGameTimer()
                    AddExplosion(compCoords.x, compCoords.y, compCoords.z, 20, 0.0, true, false, 0.0)
                    print("[Civil Unrest | AGI-OS] AI Companion deployed evasive Tactical Smoke Screen.")
                end
                
                -- Dynamic Cover and Modality
                if compHealth < (compMaxHealth * 0.4) then
                    SetPedCombatMovement(ActiveCompanionPed, 1) -- Defensive (holds cover aggressively natively)
                else
                    SetPedCombatMovement(ActiveCompanionPed, 2) -- Offensive/Flank natively
                end
            end
        end
    end
end)

-- Dynamic Event Reactions (Shootouts & High Speed Car Chases)
Citizen.CreateThread(function()
    local EventPoliceDispatchedTimer = 0
    
    while true do
        Citizen.Wait(1000)
        local playerPed = PlayerPedId()
        
        -- Event 1: Unprovoked Urban Shootouts
        if IsPedShooting(playerPed) then
            if GetGameTimer() - EventPoliceDispatchedTimer > 60000 then
                EventPoliceDispatchedTimer = GetGameTimer()
                TriggerServerEvent("civilUnrest:dispatchService", GetEntityCoords(playerPed), "POLICE")
                TriggerServerEvent("civilUnrest:updateLoyalty", "LAW", -3)
                TriggerServerEvent("civilUnrest:updateLoyalty", "CIVILIAN", -2)
                print("[Civil Unrest | AGI-OS] High-risk urban gunfire detected. Calling Police AI and deducting reputation.")
            end
            
            local peds = GetGamePool('CPed')
            local playerCoords = GetEntityCoords(playerPed)
            
            for _, ped in ipairs(peds) do
                if not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped, 1) then
                    local dist = #(GetEntityCoords(ped) - playerCoords)
                    if dist < 60.0 then
                        -- Check pedigree. (4/5 are civilians). Let them react and flee natively, preventing them from just standing around.
                        local pedType = GetPedType(ped)
                        if pedType == 4 or pedType == 5 then 
                            if not IsPedFleeing(ped) then
                                TaskSmartFleePed(ped, playerPed, 150.0, -1, false, false)
                            end
                        end
                    end
                end
            end
        end
        
        -- Event 2: Adrenaline High-Speed Chases
        if IsPedInAnyVehicle(playerPed, false) then
            local veh = GetVehiclePedIsIn(playerPed, false)
            local speed = GetEntitySpeed(veh) * 2.236936 -- Conversion to MPH
            local wanted = GetPlayerWantedLevel(PlayerId())
            
            if speed > 70.0 and wanted > 0 then
                -- Player is in a high-speed police chase. Send civilians into a panic natively.
                local peds = GetGamePool('CPed')
                local vehicleCoords = GetEntityCoords(veh)
                
                for _, ped in ipairs(peds) do
                    if not IsPedAPlayer(ped) and not IsPedInAnyVehicle(ped, false) then
                        local dist = #(GetEntityCoords(ped) - vehicleCoords)
                        if dist < 45.0 then
                             -- Force AI to dive away from roads or panic sprint from the trajectory
                             TaskReactAndFleePed(ped, playerPed)
                        end
                    end
                end
            end
        end
    end
end)

-- Hood Queen Sassy Behavior, Interaction & Vehicle Override
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        
        -- Are we near the Boardwalk zone?
        local hqZone = CivilUnrest.GangZones[15] -- Hood Queen
        local hqDist = #(coords - hqZone.coords)
        
        if hqDist < hqZone.radius then
            local peds = GetGamePool('CPed')
            for _, ped in ipairs(peds) do
                if ped ~= playerPed and not IsEntityDead(ped) then
                    local model = GetEntityModel(ped)
                    local isQueen = false
                    for _, queenModel in ipairs(hqZone.models) do
                        if model == GetHashKey(queenModel) then
                            isQueen = true
                            break
                        end
                    end
                    
                    if isQueen then
                        -- Enforce cut-off shirts or specific colorful styling natively
                        if not DecorExistOn(ped, "hq_styled") then
                            DecorSetBool(ped, "hq_styled", true)
                            SetPedComponentVariation(ped, 8, 15, math.random(0,3), 0) -- cut off shirt / sassy accessories
                            SetPedComponentVariation(ped, 3, math.random(1,4), 0, 0) -- torso adjustments
                        end
                        
                        -- Provoke and Encircling Logic
                        local dist = #(coords - GetEntityCoords(ped))
                        if dist < 25.0 and not IsPedInCombat(ped, 0) and not IsPedFleeing(ped) then
                            if dist > 3.0 then
                                -- Gather around player dynamically
                                TaskGoToEntity(ped, playerPed, -1, 2.5, 1.0, 1073741824, 0)
                            else
                                TaskTurnPedToFaceEntity(ped, playerPed, 2000)
                            end
                            
                            -- Random taunts
                            if math.random() < 0.1 then
                                PlayAmbientSpeech1(ped, "GENERIC_INSULT_HIGH", "SPEECH_PARAMS_FORCE_SHOUTED")
                                TriggerEvent("chat:addMessage", {
                                    color = {255, 105, 180},
                                    args = {"Hood Queen", "Watch your step on our boardwalk, honey. We run this."}
                                })
                                print("[Civil Unrest | AGI-OS] Hood Queen dynamically gathering and taunting player.")
                            end
                        end
                        
                        -- Colorize their vehicles (Queer colorful vehicles)
                        if IsPedInAnyVehicle(ped, false) then
                            local veh = GetVehiclePedIsIn(ped, false)
                            if not DecorExistOn(veh, "hq_veh_styled") then
                                DecorSetBool(veh, "hq_veh_styled", true)
                                SetVehicleCustomPrimaryColour(veh, 255, 105, 180) -- Hot Pink
                                SetVehicleCustomSecondaryColour(veh, 0, 255, 255) -- Cyan
                                SetVehicleNeonLightEnabled(veh, 0, true)
                                SetVehicleNeonLightEnabled(veh, 1, true)
                                SetVehicleNeonLightEnabled(veh, 2, true)
                                SetVehicleNeonLightEnabled(veh, 3, true)
                                SetVehicleNeonLightsColour(veh, 255, 105, 180)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Sensory AI Layer: Sight, Sound, Suspicion Accumulation, and Rumors
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local peds = GetGamePool('CPed')
        
        for _, ped in ipairs(peds) do
            if not IsPedAPlayer(ped) and not IsEntityDead(ped) then
                local pedType = GetPedType(ped)
                
                -- Is ped looking at the player? (Line of Sight + Suspicion)
                local hasLos = HasEntityClearLosToEntity(ped, playerPed, 17)
                local dist = #(playerCoords - GetEntityCoords(ped))
                
                if hasLos and dist < 20.0 then
                    -- If Player is Aiming or Shooting, Suspicion heavily accumulates
                    if IsPlayerFreeAiming(PlayerId()) or IsPedShooting(playerPed) then
                        local sus = DecorExistOn(ped, "ai_suspicion") and DecorGetInt(ped, "ai_suspicion") or 0
                        sus = sus + math.random(15, 30)
                        DecorSetInt(ped, "ai_suspicion", sus)
                        
                        -- If suspicion passes threshold, they act on it
                        if sus > 80 then
                            if pedType == 4 or pedType == 5 then -- Civilian
                                -- Witness System / Rumor spreading
                                if not DecorExistOn(ped, "ai_witnessed") then
                                    DecorSetBool(ped, "ai_witnessed", true)
                                    TriggerServerEvent("civilUnrest:updateLoyalty", "CIVILIAN", -1)
                                    print("[Civil Unrest | AGI-OS] Native Sensory AI: Witness detected criminal action. Rumor spreading. Street credit damaged.")
                                    TaskSmartFleePed(ped, playerPed, 150.0, -1, false, false)
                                    PlayAmbientSpeech1(ped, "GENERIC_FRIGHTENED_HIGH", "SPEECH_PARAMS_FORCE_SHOUTED")
                                end
                            else
                                -- GANG / LAW will engage
                                if not IsPedInCombat(ped, 0) then
                                    TaskCombatPed(ped, playerPed, 0, 16)
                                end
                            end
                        end
                    end
                end
                
                -- Sound Propagation System (Stealth Noise vs Shooting)
                local isStealth = GetPlayerCurrentStealthNoise(PlayerId()) > 2.0
                if (isStealth or IsPedShooting(playerPed)) and dist < 35.0 then
                     if not hasLos then
                        -- Hear noise but can't see -> Investigate
                        if not IsPedInCombat(ped, 0) and not IsPedFleeing(ped) then
                             TaskTurnPedToFaceEntity(ped, playerPed, 2000)
                             if math.random() < 0.2 then
                                PlayAmbientSpeech1(ped, "GENERIC_CURSE_MED", "SPEECH_PARAMS_STANDARD")
                             end
                        end
                     end
                end
                
                -- Gradual Suspicion Decay
                local currentSus = DecorExistOn(ped, "ai_suspicion") and DecorGetInt(ped, "ai_suspicion") or 0
                if currentSus > 0 and not (IsPlayerFreeAiming(PlayerId()) or IsPedShooting(playerPed)) then
                    DecorSetInt(ped, "ai_suspicion", math.max(0, currentSus - 5))
                end
            end
        end
    end
end)
