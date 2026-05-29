local CurrentCopDistrict = nil
local CurrentShopZone = nil

-- Monitor current zones
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        
        -- Check Cop Districts
        local foundDistrict = nil
        for _, district in ipairs(CivilUnrest.CopDistricts) do
            if #(coords - district.coords) < district.radius then
                foundDistrict = district
                break
            end
        end
        CurrentCopDistrict = foundDistrict

        -- Check Shops
        local foundShop = nil
        for _, shop in ipairs(CivilUnrest.Shops) do
            if #(coords - shop.coords) < shop.radius then
                foundShop = shop
                break
            end
        end
        CurrentShopZone = foundShop
    end
end)

-- Cop District Behaviors & Patrol overrides
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(3000)
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)

        if CurrentCopDistrict then
            local peds = GetGamePool('CPed')
            for _, cop in ipairs(peds) do
                if not IsPedAPlayer(cop) and not IsEntityDead(cop) then
                    local model = GetEntityModel(cop)
                    local isLaw = false
                    for _, lawModel in ipairs(CurrentCopDistrict.models) do
                        if model == GetHashKey(lawModel) then
                            isLaw = true
                            break
                        end
                    end
                    
                    if isLaw then
                        if not DecorExistOn(cop, "flavor_set") then
                            DecorSetBool(cop, "flavor_set", true)
                            DecorSetString(cop, "cop_flavor", CurrentCopDistrict.flavor)
                        end
                        
                        -- Flavor Logic
                        local flavor = DecorGetString(cop, "cop_flavor")
                        local dist = #(coords - GetEntityCoords(cop))
                        
                        -- If player has wanted level and interacts differently based on flavor
                        local wantedLevel = GetPlayerWantedLevel(PlayerId())
                        if dist < 20.0 and wantedLevel > 0 and flavor == "brutal" and not IsPedInCombat(cop, 0) then
                            -- Brutal cops will just attack immediately
                            TaskCombatPed(cop, playerPed, 0, 16)
                            if math.random() < 0.2 then
                                PlayAmbientSpeech1(cop, "CHALLENGE_THREATEN", "SPEECH_PARAMS_FORCE_SHOUTED")
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Police Patrol Spawner
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000) -- Check every minute
        if CurrentCopDistrict then
            local peds = GetGamePool('CPed')
            local hasPatrol = false
            for _, ped in ipairs(peds) do
                if DecorExistOn(ped, "cop_patrol_active") then
                    hasPatrol = true
                    break
                end
            end
            
            if not hasPatrol and math.random() < 0.4 then
                -- Spawn a patrol natively
                local playerPed = PlayerPedId()
                local coords = GetEntityCoords(playerPed)
                local spawnNodeHit, spawnCoords, spawnHeading = GetNthClosestVehicleNodeWithHeading(coords.x, coords.y, coords.z, 50, 9, 3.0, 2.5)
                
                if spawnNodeHit then
                    local vehModel = GetHashKey("police")
                    RequestModel(vehModel)
                    while not HasModelLoaded(vehModel) do Citizen.Wait(100) end
                    
                    local copModel = GetHashKey(CurrentCopDistrict.models[1])
                    RequestModel(copModel)
                    while not HasModelLoaded(copModel) do Citizen.Wait(100) end
                    
                    local patrolVeh = CreateVehicle(vehModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnHeading, true, false)
                    local patrolCop = CreatePedInsideVehicle(patrolVeh, 26, copModel, -1, true, false)
                    
                    DecorSetBool(patrolCop, "cop_patrol_active", true)
                    DecorSetBool(patrolCop, "flavor_set", true)
                    DecorSetString(patrolCop, "cop_flavor", CurrentCopDistrict.flavor)
                    
                    TaskVehicleDriveWander(patrolCop, patrolVeh, 20.0, 786603)
                    SetEntityAsNoLongerNeeded(patrolVeh)
                    SetEntityAsNoLongerNeeded(patrolCop)
                    print("[Civil Unrest | AGI-OS] Dispatched District Patrol in " .. CurrentCopDistrict.name)
                end
            end
        end
    end
end)

-- Global Export for Radial Overrides
function GetCurrentShopZone()
    return CurrentShopZone
end

function GetCurrentCopDistrict()
    return CurrentCopDistrict
end
