-- /civil_unrest/client/services.lua
Citizen.CreateThread(function()
    local isDeadState = false
    local fireCooldown = 0

    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()

        -- Fatality Target Tracking
        local isDead = IsEntityDead(ped)
        if isDead and not isDeadState then
            isDeadState = true
            print("[Civil Unrest | AGI-OS] Target Status: Deceased. Dispatching EMS Native AI.")
            TriggerServerEvent("civilUnrest:dispatchService", GetEntityCoords(ped), "EMS")
        elseif not isDead and isDeadState then
            isDeadState = false
        end

        -- Pyromania Target Tracking
        if GetEntityOnFire(ped) and GetGameTimer() - fireCooldown > 60000 then
            fireCooldown = GetGameTimer()
            print("[Civil Unrest | AGI-OS] Combustible Incident Detected natively. Dispatching Fire AI.")
            TriggerServerEvent("civilUnrest:dispatchService", GetEntityCoords(ped), "FIRE")
        end
    end
end)

RegisterNetEvent("civilUnrest:forceSpawnService")
AddEventHandler("civilUnrest:forceSpawnService", function(coords, serviceType)
    Citizen.CreateThread(function()
        local vehHash, pedHash
        if serviceType == "EMS" then
            vehHash = GetHashKey("ambulance")
            pedHash = GetHashKey("s_m_m_paramedic_01")
        elseif serviceType == "FIRE" then
            vehHash = GetHashKey("firetruk")
            pedHash = GetHashKey("s_m_y_fireman_01")
        elseif serviceType == "POLICE" then
            vehHash = GetHashKey("police")
            pedHash = GetHashKey("s_m_y_cop_01")
        end

        RequestModel(vehHash)
        RequestModel(pedHash)
        local t = 0
        while (not HasModelLoaded(vehHash) or not HasModelLoaded(pedHash)) and t < 50 do
            Citizen.Wait(100); t = t + 1
        end

        -- Find logical spawn node slightly away from the destination natively
        local success, spawnNode, spawnHeading = GetClosestVehicleNodeWithHeading(coords.x + math.random(-150, 150), coords.y + math.random(-150, 150), coords.z, 1, 3, 0)
        
        -- Fallback if no roads are detected in proximity limit
        if not success or not spawnNode then
            spawnNode = vector3(coords.x + 50.0, coords.y + 50.0, coords.z)
            spawnHeading = 0.0
        end

        local veh = CreateVehicle(vehHash, spawnNode.x, spawnNode.y, spawnNode.z, spawnHeading, true, false)
        SetVehicleEngineOn(veh, true, true, false)
        SetVehicleSiren(veh, true)

        local driver = CreatePedInsideVehicle(veh, 4, pedHash, -1, true, false)
        local passenger = CreatePedInsideVehicle(veh, 4, pedHash, 0, true, false)

        -- Dispatch Native Driving Pathfinding straight to the client coordinate
        TaskVehicleDriveToCoordLongrange(driver, veh, coords.x, coords.y, coords.z, 30.0, 786603, 10.0)

        -- Provide different voice lines and logic vocabularies based on arrival sequences
        Citizen.CreateThread(function()
            local deployTime = GetGameTimer()
            while true do
                Citizen.Wait(1000)
                if #(GetEntityCoords(veh) - coords) < 25.0 or (GetGameTimer() - deployTime > 60000) then
                    TaskLeaveVehicle(driver, veh, 0)
                    if DoesEntityExist(passenger) then TaskLeaveVehicle(passenger, veh, 0) end
                    Citizen.Wait(1500)
                    
                    TaskGoToCoordAnyMeans(driver, coords.x, coords.y, coords.z, 1.5, 0, 0, 786603, 0xbf800000)
                    if DoesEntityExist(passenger) then TaskGoToCoordAnyMeans(passenger, coords.x, coords.y, coords.z, 1.5, 0, 0, 786603, 0xbf800000) end
                    
                    Citizen.Wait(3000)
                    
                    -- Dynamic Audio and Scenario Generation mapped to service archetype
                    local scenarioId = math.random(1, 3)
                    if serviceType == "EMS" then
                        if scenarioId == 1 then
                            PlayAmbientSpeech1(driver, "GENERIC_SHOCKED_HIGH", "SPEECH_PARAMS_FORCE_SHOUTED")
                            TriggerEvent("chat:addMessage", { color = {255, 50, 50}, args = {"[EMS Unit]", "Stay with me! We've got major trauma here!"} })
                        elseif scenarioId == 2 then
                            PlayAmbientSpeech1(driver, "GET_OUT_OF_WAY", "SPEECH_PARAMS_FORCE_SHOUTED")
                            TriggerEvent("chat:addMessage", { color = {255, 50, 50}, args = {"[EMS Unit]", "Clear the area! We need space to work on the victim!"} })
                        else
                            PlayAmbientSpeech1(driver, "MEDIC", "SPEECH_PARAMS_STANDARD")
                            TriggerEvent("chat:addMessage", { color = {255, 50, 50}, args = {"[EMS Unit]", "Checking vitals. Hang in there."} })
                            TaskStartScenarioInPlace(driver, "CODE_HUMAN_MEDIC_TEND_TO_DEAD", 0, true)
                        end
                    elseif serviceType == "FIRE" then
                        if scenarioId == 1 then
                            PlayAmbientSpeech1(driver, "FIRE", "SPEECH_PARAMS_FORCE_SHOUTED")
                            TriggerEvent("chat:addMessage", { color = {255, 100, 0}, args = {"[Fire Rescue]", "We have active combustion! Rolling out hoses!"} })
                        elseif scenarioId == 2 then
                            PlayAmbientSpeech1(driver, "GET_OUT_OF_WAY", "SPEECH_PARAMS_FORCE_SHOUTED")
                            TriggerEvent("chat:addMessage", { color = {255, 100, 0}, args = {"[Fire Rescue]", "Back away from the heat source! It's unstable!"} })
                        else
                            PlayAmbientSpeech1(driver, "GENERIC_CURSE_HIGH", "SPEECH_PARAMS_FORCE_SHOUTED")
                            TriggerEvent("chat:addMessage", { color = {255, 100, 0}, args = {"[Fire Rescue]", "Fire spreading fast, secure the perimeter!"} })
                        end
                    elseif serviceType == "POLICE" then
                        if scenarioId == 1 then
                            PlayAmbientSpeech1(driver, "CHALLENGE_THREATEN", "SPEECH_PARAMS_FORCE_SHOUTED")
                            TriggerEvent("chat:addMessage", { color = {50, 50, 255}, args = {"[LSPD Unit]", "Disperse immediately or you will be arrested!"} })
                            TaskAimGunAtCoord(driver, coords.x, coords.y, coords.z + 1.0, 5000, false, false)
                        elseif scenarioId == 2 then
                            PlayAmbientSpeech1(driver, "STAY_THERE", "SPEECH_PARAMS_FORCE_SHOUTED")
                            TriggerEvent("chat:addMessage", { color = {50, 50, 255}, args = {"[LSPD Unit]", "Hands where I can see them! Integrating scene perimeter."} })
                        else
                            PlayAmbientSpeech1(driver, "BACKUP_REQUEST", "SPEECH_PARAMS_FORCE_SHOUTED")
                            TriggerEvent("chat:addMessage", { color = {50, 50, 255}, args = {"[LSPD Unit]", "We've arrived on scene. Dispatch, logging response to caller native coordinates."} })
                            TaskStartScenarioInPlace(driver, "WORLD_HUMAN_GUARD_STAND", 0, true)
                        end
                    end
                    
                    break
                end
            end
        end)
    end)
end)
