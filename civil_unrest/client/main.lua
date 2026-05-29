local isRiotActive = false
local currentWantedLvl = 0
local currentGangZone = nil

-- Initialize Minimap Gang Zones
Citizen.CreateThread(function()
    for i, zone in ipairs(CivilUnrest.GangZones) do
        local blip = AddBlipForRadius(zone.coords.x, zone.coords.y, zone.coords.z, zone.radius)
        SetBlipHighDetail(blip, true)
        SetBlipColour(blip, zone.color)
        SetBlipAlpha(blip, zone.alpha)
    end
    if CivilUnrest.DebugMode then
        print("[Civil Unrest | AGI-OS] Initialized Gang Territories on Minimap")
    end
end)

-- Radial Menu Controller Hook (Controller Friendly / NUI Bridge)
RegisterCommand("+openCivilMenu", function()
    -- High level native mapping for controller and keyboard
    -- Bridges UI for interacting with AI models natively
    SendNUIMessage({ action = "openRadialMenu" })
    -- Immersive blurring
    SetTimecycleModifier("hud_def_blur")
    print("[Civil Unrest | AGI-OS] Opening AI Interaction Radial Menu")
end, false)
RegisterKeyMapping("+openCivilMenu", "Civil Unrest: System Interaction Radial", "keyboard", "F1")

-- Add raycasting for AI interactions
function GetTargetedEntity()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local forward = GetEntityForwardVector(playerPed)
    local rayEnd = coords + (forward * 5.0)
    
    local rayHandle = CastRayPointToPoint(coords.x, coords.y, coords.z, rayEnd.x, rayEnd.y, rayEnd.z, 10, playerPed, 0)
    local _, hit, endCoords, _, entityHit = GetRaycastResult(rayHandle)
    
    if hit == 1 then
        local type = GetEntityType(entityHit)
        if type == 1 or type == 2 then
            return entityHit, type
        end
    end
    return nil, nil
end

local currentTargetEntity = nil
local currentTargetType = nil
local ActiveCompanionPed = nil
CompanionArmory = {}

local OwnedVehicles = {}
function VehIsOwnedByPlayer(plate)
    return OwnedVehicles[plate] == true
end

LocalPlayerLoyalty = {}
RegisterNetEvent("civilUnrest:syncLoyalty")
AddEventHandler("civilUnrest:syncLoyalty", function(data)
    LocalPlayerLoyalty = data
end)

function GetPedFaction(pedModel)
    for _, zone in ipairs(CivilUnrest.GangZones) do
        for _, gm in ipairs(zone.models or {}) do
            if pedModel == GetHashKey(gm) then return zone.name end
        end
    end
    local copModels = { GetHashKey("s_m_y_cop_01"), GetHashKey("s_f_y_cop_01"), GetHashKey("s_m_y_sheriff_01"), GetHashKey("s_m_y_hwaycop_01") }
    for _, cm in ipairs(copModels) do
        if pedModel == cm then return "LAW" end
    end
    return "CIVILIAN"
end

RegisterCommand("+interactNPC", function()
    local entityHit, hitType = nil, nil
    local playerPed = PlayerPedId()

    if IsPedInAnyVehicle(playerPed, false) then
        entityHit = GetVehiclePedIsIn(playerPed, false)
        hitType = 2
    else
        entityHit, hitType = GetTargetedEntity()
    end

    if entityHit then
        currentTargetEntity = entityHit
        currentTargetType = hitType
        local contextOptions = {}

        if hitType == 1 then
            local targetPed = entityHit
            local pedModel = GetEntityModel(targetPed)
            
            -- Logic vocabulary: determining NPC class via model hash or decorators
            -- For demonstration, grouping context actions by AI model types
            local shopkeeperModels = { GetHashKey("mp_m_shopkeep_01") }
            local gangLeaderModels = { GetHashKey("g_m_y_ballaeast_01"), GetHashKey("g_m_y_famca_01") }
            
            local isShopkeeper = false
            for _, hash in ipairs(shopkeeperModels) do
                if pedModel == hash then isShopkeeper = true end
            end
            
            local isGangLeader = false
            for _, hash in ipairs(gangLeaderModels) do
                if pedModel == hash then isGangLeader = true end
            end

            local isCompanion = (currentTargetEntity == ActiveCompanionPed)

            if isCompanion then
                contextOptions = {
                    { action = "chat", label = "Converse with Companion" },
                    { action = "share_weapon", label = "Share Held Weapon & Gear" },
                    { action = "companion_stay", label = "Wait Here" },
                    { action = "companion_follow", label = "Follow Me" },
                    { action = "companion_dismiss", label = "Dismiss Companion" }
                }
            else
                local factionName = GetPedFaction(pedModel)
                local isGangMember = (factionName ~= "LAW" and factionName ~= "CIVILIAN")
                local isLaw = (factionName == "LAW")
                local isCivilian = (factionName == "CIVILIAN")
                local activeLoyalty = factionName and (LocalPlayerLoyalty[factionName] or 0) or 0
                local copFlavor = DecorExistOn(targetPed, "flavor_set") and DecorGetString(targetPed, "cop_flavor") or nil

                -- Base AI Native Generation Hooks
                table.insert(contextOptions, { action = "chat", label = "Engage Conversation" })
                table.insert(contextOptions, { action = "threaten", label = "Intimidate NPC" })
                table.insert(contextOptions, { action = "gesture_greet", label = "Gesture: Friendly Greet" })
                table.insert(contextOptions, { action = "gesture_intimidate", label = "Gesture: Aggressive Flex" })

                if isGangMember and not ActiveCompanionPed then
                    table.insert(contextOptions, { action = "recruit_companion", label = "Recruit Gang AI" })
                end

                if isGangMember then
                    table.insert(contextOptions, { action = "buy_drugs", label = "Buy Contraband / Drugs" })
                    table.insert(contextOptions, { action = "sell_drugs", label = "Sell Supply to Corner" })
                    if CivilUnrest.Economy and CivilUnrest.Economy.Merchandise[factionName] then
                        table.insert(contextOptions, { action = "buy_merch", label = "Purchase " .. factionName .. " Merchandise" })
                    end
                end

                if isLaw then
                    if copFlavor == "corrupt" then
                         table.insert(contextOptions, { action = "law_district_bribe", label = "Pay Off Corrupt Cop" })
                    end
                    if activeLoyalty > 20 then
                        table.insert(contextOptions, { action = "law_backup", label = "Request Backup" })
                    end
                    if activeLoyalty < -50 then
                        table.insert(contextOptions, { action = "law_bribe", label = "Bribe Officer" })
                    end
                end
                
                if isCivilian and activeLoyalty > 10 then
                    table.insert(contextOptions, { action = "civ_rumors", label = "Ask for Rumors" })
                end

                local activeShop = GetCurrentShopZone and GetCurrentShopZone() or nil
                if activeShop then
                    for _, shopItem in ipairs(activeShop.items) do
                       table.insert(contextOptions, { action = "buy_shop_item", args = { itemId = shopItem.item, price = shopItem.price }, label = "Buy " .. shopItem.item .. " ($" .. shopItem.price .. ")" })
                    end
                elseif isShopkeeper then
                    table.insert(contextOptions, { action = "buy_items", label = "Purchase Contraband" })
                    table.insert(contextOptions, { action = "extort", label = "Extort Shopkeeper" })
                elseif isGangLeader then
                    table.insert(contextOptions, { action = "start_mission", label = "Request Task" })
                    table.insert(contextOptions, { action = "get_intel", label = "Acquire Intel" })
                elseif not isLaw then
                    table.insert(contextOptions, { action = "rob", label = "Mug Citizen" })
                end
                
                -- Epoch Context Injections
                if _G.CurrentEpoch == "SYNDICATE" then
                    table.insert(contextOptions, { action = "stock_takeover", label = "Initiate Corporate Takeover" })
                    table.insert(contextOptions, { action = "wiretap", label = "Wiretap Faction Channels" })
                elseif _G.CurrentEpoch == "NEON_NIGHTS" then
                    table.insert(contextOptions, { action = "install_cyberware", label = "Visit Back-Alley Ripperdoc" })
                end
                
                -- Override context natively if in active territory limits
                if currentGangZone then
                    table.insert(contextOptions, { action = "territory_bribe", label = "Pay " .. currentGangZone.name .. " Tax" })
                    table.insert(contextOptions, { action = "territory_mission", label = "Local Turf Work" })
                    
                    if _G.CurrentEpoch == "TOTAL_WAR" then
                        table.insert(contextOptions, { action = "buy_turf_cameras", label = "Buy Turf Upgrade: Security Cameras" })
                        table.insert(contextOptions, { action = "buy_turf_barricades", label = "Buy Turf Upgrade: Reinforcements" })
                    end
                end
            end
        elseif hitType == 2 then
            -- Vehicle Logic
            local plate = GetVehicleNumberPlateText(currentTargetEntity)
            if VehIsOwnedByPlayer(plate) then
                table.insert(contextOptions, { action = "veh_hood", label = "Toggle Hood" })
                table.insert(contextOptions, { action = "veh_trunk", label = "Open Trunk / Arsenal" })
                table.insert(contextOptions, { action = "veh_doors", label = "Toggle Doors" })
            else
                table.insert(contextOptions, { action = "veh_claim", label = "Claim / Hotwire Vehicle" })
                table.insert(contextOptions, { action = "veh_hood", label = "Toggle Hood" })
                table.insert(contextOptions, { action = "veh_trunk", label = "Pry Open Trunk" })
            end
        end
        
        SendNUIMessage({
            type = "OPEN_INTERACTION_MENU",
            options = contextOptions
        })
        SetNuiFocus(true, true)
        print("[Civil Unrest | AGI-OS] Hooked NUI menu for entity: " .. entityHit)
    else
        print("[Civil Unrest | AGI-OS] No valid AI entity or Vehicle in range.")
    end
end, false)
RegisterKeyMapping("+interactNPC", "Civil Unrest: Interrogate/Interact with AI", "keyboard", "E")

RegisterNUICallback("closeMenu", function(data, cb)
    SetNuiFocus(false, false)
    cb("ok")
end)

RegisterNUICallback("selectOption", function(data, cb)
    if data.action == "chat" or data.action == "threaten" then
        -- Keep focus, UI handles hiding buttons and showing typing
        SendNUIMessage({ type = "SHOW_TYPING" })
        local model = currentTargetEntity and GetEntityModel(currentTargetEntity) or 0
        TriggerServerEvent("civilUnrest:generateDialogue", model, data.action)
    elseif data.action == "gesture_greet" then
        SetNuiFocus(false, false)
        TriggerEvent("civilUnrest:playGesture", "greet")
    elseif data.action == "gesture_intimidate" then
        SetNuiFocus(false, false)
        TriggerEvent("civilUnrest:playGesture", "intimidate")
    elseif data.action == "recruit_companion" then
        if currentTargetEntity and currentTargetType == 1 then
            local pedModel = GetEntityModel(currentTargetEntity)
            local gangName = GetPedFaction(pedModel)
            local loyalty = gangName and (LocalPlayerLoyalty[gangName] or 0) or 0
            
            if loyalty < 0 then
                SetNuiFocus(false, false)
                print("[Civil Unrest | AGI-OS] Loyalty too low. Recruitment rejected.")
                SendNUIMessage({ type = "UPDATE_DIALOGUE", text = "I don't roll with snakes. Get out of my face." })
                if loyalty < -50 then
                    -- Brutal betrayal
                    TaskCombatPed(currentTargetEntity, PlayerPedId(), 0, 16)
                    TriggerServerEvent("civilUnrest:updateLoyalty", gangName, -5)
                end
                cb("ok")
                return
            end

            SendNUIMessage({ type = "OPEN_NAMING_BOX" })
        else
            SetNuiFocus(false, false)
        end
    elseif data.action == "share_weapon" then
        SetNuiFocus(false, false)
        if ActiveCompanionPed then
            local _, weaponHash = GetCurrentPedWeapon(PlayerPedId(), true)
            if weaponHash ~= GetHashKey("WEAPON_UNARMED") then
                GiveWeaponToPed(ActiveCompanionPed, weaponHash, 500, false, true)
                CompanionArmory[weaponHash] = true
                
                local playerArmor = GetPedArmour(PlayerPedId())
                if playerArmor > 0 then
                    SetPedArmour(ActiveCompanionPed, playerArmor)
                end
                
                print("[Civil Unrest | AGI-OS] Transferred player weapon and armor to companion natively.")
            else
                print("[Civil Unrest | AGI-OS] Cannot share unarmed state.")
            end
        end
    elseif data.action == "companion_stay" then
        SetNuiFocus(false, false)
        if ActiveCompanionPed then
            ClearPedTasks(ActiveCompanionPed)
            RemovePedFromGroup(ActiveCompanionPed)
            TaskStandStill(ActiveCompanionPed, -1)
            print("[Civil Unrest | AGI-OS] AI Companion holding physical position.")
        end
    elseif data.action == "companion_follow" then
        SetNuiFocus(false, false)
        if ActiveCompanionPed then
            SetPedAsGroupMember(ActiveCompanionPed, GetPlayerGroup(PlayerId()))
            print("[Civil Unrest | AGI-OS] AI Companion regrouping.")
        end
    elseif data.action == "companion_dismiss" then
        SetNuiFocus(false, false)
        if ActiveCompanionPed then
            RemovePedFromGroup(ActiveCompanionPed)
            TaskWanderStandard(ActiveCompanionPed, 10.0, 10)
            ActiveCompanionPed = nil
            print("[Civil Unrest | AGI-OS] AI Companion dismissed to wander engine state.")
        end
    elseif data.action == "rob" then
        SetNuiFocus(false, false)
        local pedModel = currentTargetEntity and GetEntityModel(currentTargetEntity) or 0
        local factionName = GetPedFaction(pedModel)
        if factionName then TriggerServerEvent("civilUnrest:updateLoyalty", factionName, -15) end
        TriggerServerEvent("civilUnrest:updateLoyalty", "LAW", -5)
        if currentTargetEntity and currentTargetType == 1 then
            TaskHandsUp(currentTargetEntity, 5000, PlayerPedId(), -1, true)
        end
        print("[Civil Unrest | AGI-OS] Citizen mugging initiated natively.")
    elseif data.action == "buy_drugs" or data.action == "sell_drugs" or data.action == "buy_merch" then
        SetNuiFocus(false, false)
        local pedModel = currentTargetEntity and GetEntityModel(currentTargetEntity) or 0
        local factionName = GetPedFaction(pedModel)
        TriggerServerEvent("civilUnrest:ecoInteract", factionName, data.action)
    elseif data.action == "buy_shop_item" then
        SetNuiFocus(false, false)
        local price = data.args.price
        local itemId = data.args.itemId
        TriggerServerEvent("civilUnrest:buyShopItem", itemId, price)
    elseif data.action == "law_district_bribe" then
        SetNuiFocus(false, false)
        TriggerServerEvent("civilUnrest:corruptCopBribe")
    elseif data.action == "law_backup" then
        SetNuiFocus(false, false)
        TriggerServerEvent("civilUnrest:dispatchService", GetEntityCoords(PlayerPedId()), "POLICE")
        TriggerServerEvent("civilUnrest:updateLoyalty", "LAW", -2) -- Minor penalty for consuming resources
        print("[Civil Unrest | AGI-OS] Police backup requested cleanly.")
    elseif data.action == "law_bribe" then
        SetNuiFocus(false, false)
        TriggerServerEvent("civilUnrest:updateLoyalty", "LAW", 15)
        print("[Civil Unrest | AGI-OS] Officer bribed to look the other way.")
    elseif data.action == "civ_rumors" then
        SetNuiFocus(false, false)
        SendNUIMessage({ type = "UPDATE_DIALOGUE", text = "I heard the local syndicates are moving product tightly tonight. Be careful." })
        TriggerServerEvent("civilUnrest:updateLoyalty", "CIVILIAN", 2)
        print("[Civil Unrest | AGI-OS] Civilian shared local street rumors.")
    elseif data.action == "veh_claim" then
        SetNuiFocus(false, false)
        if currentTargetEntity and currentTargetType == 2 then
            local plate = GetVehicleNumberPlateText(currentTargetEntity)
            OwnedVehicles[plate] = true
            SetVehicleDoorsLocked(currentTargetEntity, 1) -- Set unlocked
            TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_WELDING", 0, true)
            Citizen.CreateThread(function()
                Citizen.Wait(3000)
                ClearPedTasks(PlayerPedId())
                print("[Civil Unrest | AGI-OS] Vehicle claimed. Plate: " .. plate)
            end)
        end
    elseif data.action == "veh_hood" then
        SetNuiFocus(false, false)
        if currentTargetEntity and currentTargetType == 2 then
            local isOpen = GetVehicleDoorAngleRatio(currentTargetEntity, 4) > 0.1
            if isOpen then
                SetVehicleDoorShut(currentTargetEntity, 4, false)
            else
                SetVehicleDoorOpen(currentTargetEntity, 4, false, false)
            end
        end
    elseif data.action == "veh_trunk" then
        SetNuiFocus(false, false)
        if currentTargetEntity and currentTargetType == 2 then
            local isOpen = GetVehicleDoorAngleRatio(currentTargetEntity, 5) > 0.1
            if isOpen then
                SetVehicleDoorShut(currentTargetEntity, 5, false)
            else
                SetVehicleDoorOpen(currentTargetEntity, 5, false, false)
                local plate = GetVehicleNumberPlateText(currentTargetEntity)
                if VehIsOwnedByPlayer(plate) then
                    print("[Civil Unrest | AGI-OS] Retrieving arsenal from personal vehicle trunk...")
                    -- Provide weapons from trunk natively
                    GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_CARBINERIFLE"), 250, false, true)
                    GiveWeaponToPed(PlayerPedId(), GetHashKey("WEAPON_PUMPSHOTGUN"), 50, false, false)
                    SetPedArmour(PlayerPedId(), 100)
                    print("[Civil Unrest | AGI-OS] Arsenal retrieved successfully for drive-by/gang war.")
                else
                    print("[Civil Unrest | AGI-OS] Emptied unowned trunk. Found nothing.")
                end
            end
        end
    elseif data.action == "veh_doors" then
        SetNuiFocus(false, false)
        if currentTargetEntity and currentTargetType == 2 then
            local doorsOpen = GetVehicleDoorAngleRatio(currentTargetEntity, 0) > 0.1
            for i=0, 3 do
                if doorsOpen then
                    SetVehicleDoorShut(currentTargetEntity, i, false)
                else
                    SetVehicleDoorOpen(currentTargetEntity, i, false, false)
                end
            end
        end
    elseif data.action == "stock_takeover" then
        SetNuiFocus(false, false)
        local pedModel = currentTargetEntity and GetEntityModel(currentTargetEntity) or 0
        local factionName = GetPedFaction(pedModel)
        TriggerServerEvent("civilUnrest:stockTakeover", factionName)
        print("[Civil Unrest | AGI-OS] Stock Takeover Initiated for " .. tostring(factionName))
    elseif data.action == "buy_turf_cameras" then
        SetNuiFocus(false, false)
        if currentGangZone then
            TriggerServerEvent("civilUnrest:buyTurfUpgrade", currentGangZone.name, "cameras")
        end
    elseif data.action == "buy_turf_barricades" then
        SetNuiFocus(false, false)
        if currentGangZone then
            TriggerServerEvent("civilUnrest:buyTurfUpgrade", currentGangZone.name, "barricades")
        end
    elseif data.action == "wiretap" then
        SetNuiFocus(false, false)
        SendNUIMessage({ type = "UPDATE_DIALOGUE", text = "[WIRETAP ACTIVE] Intercepting local communications..." })
        print("[Civil Unrest | AGI-OS] Wiretap engaged natively.")
    elseif data.action == "install_cyberware" then
        SetNuiFocus(false, false)
        TriggerEvent("civilUnrest:installCyberware", "reflex_booster")
        SendNUIMessage({ type = "UPDATE_DIALOGUE", text = "[RIPPERDOC] Reflex Booster installed. Your speed is multiplied." })
    elseif data.action == "territory_bribe" then
        SetNuiFocus(false, false)
        if currentGangZone then
            TriggerServerEvent("civilUnrest:updateLoyalty", currentGangZone.name, 10)
            print("[Civil Unrest | AGI-OS] Territory tax paid.")
        end
    elseif data.action == "territory_mission" then
        SetNuiFocus(false, false)
        if currentGangZone then
            TriggerServerEvent("civilUnrest:updateLoyalty", currentGangZone.name, 25)
            print("[Civil Unrest | AGI-OS] Local turf work completed.")
        end
    else
        SetNuiFocus(false, false)
        print("[Civil Unrest | AGI-OS] Client executed NUI option: " .. data.action)
    end
    cb("ok")
end)

RegisterNUICallback("recruitCompanionWithName", function(data, cb)
    SetNuiFocus(false, false)
    if currentTargetPed then
        local pedModel = GetEntityModel(currentTargetPed)
        local gangName = GetPedFaction(pedModel)
        local loyalty = gangName and (LocalPlayerLoyalty[gangName] or 0) or 0
        
        local companionName = data.name or "Unknown"

        -- Assign to Player Group Natively
        local group = GetPlayerGroup(PlayerId())
        if group == 0 then
            -- Failsafe engine group creation natively
            group = CreateGroup(0)
            SetPedAsGroupLeader(PlayerPedId(), group)
        end
        SetPedAsGroupMember(currentTargetPed, group)
        SetPedNeverLeavesGroup(currentTargetPed, true)
        GiveWeaponToPed(currentTargetPed, GetHashKey("WEAPON_APPISTOL"), 500, false, true)
        
        -- Apply a distinct visual identifier (e.g. unique bandana/mask - natively set component)
        -- Using generic props/components that work on most peds as identifiers
        SetPedPropIndex(currentTargetPed, 0, 14, 0, 0) -- Hat/Helmet identifier
        SetPedComponentVariation(currentTargetPed, 8, 15, 0, 0) -- Undershirt/Accessory identifier
        
        -- Bond stats mapping (scaled by loyalty)
        local healthBonus = math.floor((loyalty / 100) * 200)
        SetEntityMaxHealth(currentTargetPed, 400 + healthBonus)
        SetEntityHealth(currentTargetPed, 400 + healthBonus)
        SetPedCombatAbility(currentTargetPed, 100) 
        
        -- Advanced Combat Init natively
        SetPedCombatMovement(currentTargetPed, 2) -- Offensive/Flanking
        SetPedCombatRange(currentTargetPed, 1) -- Medium Range
        SetPedCombatAttributes(currentTargetPed, 0, true) -- Can Use Cover
        SetPedCombatAttributes(currentTargetPed, 5, true) -- Fight unarmed peds
        SetPedCombatAttributes(currentTargetPed, 46, true) -- Fight armed peds
        
        ActiveCompanionPed = currentTargetPed
        CompanionArmory = { [GetHashKey("WEAPON_APPISTOL")] = true }
        print("[Civil Unrest | AGI-OS] AI Companion '" .. companionName .. "' successfully bonded natively. (Loyalty Bonus Applied)")
        
        TriggerServerEvent("civilUnrest:registerCompanion", companionName, pedModel)
        
        SendNUIMessage({ type = "UPDATE_DIALOGUE", text = loyalty > 50 and "Anything for the boss. We ride." or "I got your back. We roll together now." })
    end
    cb("ok")
end)

RegisterNetEvent("civilUnrest:receiveDialogue")
AddEventHandler("civilUnrest:receiveDialogue", function(text)
    SendNUIMessage({
        type = "UPDATE_DIALOGUE",
        text = text
    })
    print("[Civil Unrest | AGI-OS] Received Native AI Dialogue.")
end)

RegisterNetEvent("civilUnrest:triggerBust")
AddEventHandler("civilUnrest:triggerBust", function()
    -- Set wanted level and attach nearby Law ped natively
    SetPlayerWantedLevel(PlayerId(), 3, false)
    SetPlayerWantedLevelNow(PlayerId(), false)
    if currentTargetEntity then
        -- Simulating arrest animation logic
        TaskHandsUp(PlayerPedId(), 5000, currentTargetEntity, -1, true)
        ClearPedTasks(currentTargetEntity)
        GiveWeaponToPed(currentTargetEntity, GetHashKey("WEAPON_COMBATPISTOL"), 500, false, true)
        TaskAimGunAtEntity(currentTargetEntity, PlayerPedId(), 5000, false)
    end
end)

RegisterNetEvent("civilUnrest:clearWantedLevel")
AddEventHandler("civilUnrest:clearWantedLevel", function()
    SetPlayerWantedLevel(PlayerId(), 0, false)
    SetPlayerWantedLevelNow(PlayerId(), false)
    print("[Civil Unrest | AGI-OS] Wanted Level cleared natively by Corrupt Cop Bribe.")
end)

RegisterNetEvent("civilUnrest:equipMerch")
AddEventHandler("civilUnrest:equipMerch", function(factionName, item)
    -- Visual natively mapped component equipping based on gang
    local playerPed = PlayerPedId()
    SetPedPropIndex(playerPed, 0, math.random(1, 10), 0, 0)
    SetPedComponentVariation(playerPed, 8, math.random(1, 10), 0, 0)
    print("[Civil Unrest | AGI-OS] Active Gang merchandise equipped natively: " .. tostring(item))
end)

-- AI Service Skills modified by dynamic Wanted Levels
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
        local myPed = PlayerPedId()
        local currentWantedLvl = GetPlayerWantedLevel(PlayerId())
        
        -- Logic vocabulary true to app themes: Wanted level disrupts local NPC capabilities
        if currentWantedLvl > 0 then
            -- Modulating pawn shop negotiation windows and mechanic repairs directly based on local authority stress
            StatSetInt(GetHashKey("MP0_STAMINA"), math.max(0, 100 - (currentWantedLvl * 15)), true)
            
            -- NEW TRIGGER: High Wanted Level attracts direct media attention
            if currentWantedLvl >= 3 then
                if math.random(1, 100) > 85 then -- 15% chance to trigger per loop if high wanted
                    TriggerServerEvent("civilUnrest:reportHighProfileCrime", GetEntityCoords(myPed))
                end
            end
        end
    end
end)

-- Execute News Reporter AI Sequence
RegisterNetEvent("civilUnrest:spawnNewsEvent")
AddEventHandler("civilUnrest:spawnNewsEvent", function(coords, eventType)
    Citizen.CreateThread(function()
        local vanHash = GetHashKey("rumpo") -- Default Weazel News native ID
        local pedHash = GetHashKey("a_m_m_paparazzi_01") -- Media Native Ped
        
        RequestModel(vanHash)
        RequestModel(pedHash)
        local timer = 0
        while (not HasModelLoaded(vanHash) or not HasModelLoaded(pedHash)) and timer < 50 do 
            Citizen.Wait(100) 
            timer = timer + 1
        end
        
        local targetX = coords.x + math.random(-25, 25)
        local targetY = coords.y + math.random(-25, 25)
        
        local newsVan = CreateVehicle(vanHash, targetX, targetY, coords.z, 0.0, true, false)
        SetVehicleLivery(newsVan, 1) -- Set exclusively to Weazel News
        
        -- Core Ped Instance
        local reporterPed = CreatePed(4, pedHash, targetX + 2.0, targetY, coords.z, 0.0, true, false)
        SetPedKeepTask(reporterPed, true)
        
        -- Command pathfinding
        TaskGoToCoordAnyMeans(reporterPed, coords.x, coords.y, coords.z, 1.5, 0, 0, 786603, 0xbf800000)
        print(string.format("[Civil Unrest | AGI-OS] Dispatching Media AI - Type: %s", eventType))

        Citizen.Wait(6000) -- Simple wait for arrival time to scene
        
        RequestAnimDict("amb@world_human_paparazzi@male@base")
        timer = 0
        while not HasAnimDictLoaded("amb@world_human_paparazzi@male@base") and timer < 50 do 
            Citizen.Wait(50) 
            timer = timer + 1
        end

        if eventType == "interview" then
            -- Engage closest civilian
            local closePeds = GetGamePool("CPed")
            local targetTarget = nil
            for _, ped in ipairs(closePeds) do
                if ped ~= reporterPed and ped ~= PlayerPedId() then
                    local dist = #(GetEntityCoords(ped) - GetEntityCoords(reporterPed))
                    if dist < 15.0 then
                        targetTarget = ped
                        break
                    end
                end
            end
            
            if targetTarget then
                TaskTurnPedToFaceEntity(reporterPed, targetTarget, -1)
                TaskPlayAnim(reporterPed, "amb@world_human_paparazzi@male@base", "base", 8.0, -8.0, -1, 1, 0, false, false, false)
                PlayPedAmbientSpeechNative(reporterPed, "GENERIC_HI", "SPEECH_PARAMS_FORCE")
            else
                TaskStartScenarioInPlace(reporterPed, "WORLD_HUMAN_STAND_MOBILE", 0, true)
            end
        else
            -- Documenting violence / player actions directly
            TaskTurnPedToFaceEntity(reporterPed, PlayerPedId(), -1)
            TaskPlayAnim(reporterPed, "amb@world_human_paparazzi@male@base", "base", 8.0, -8.0, -1, 1, 0, false, false, false)
        end
    end)
end)

-- Execute Weekly Riot Mechanics natively
RegisterNetEvent("civilUnrest:startRiot")
AddEventHandler("civilUnrest:startRiot", function()
    isRiotActive = true
    SetRiotModeEnabled(true)
    -- Elevate combat modifiers for civilian peds
    SetPedChaosDefend(GetPlayerPed(-1), true)
    print("[Civil Unrest | AGI-OS] EMERGENCY: Weekly Civil Unrest Initiated. NPC logic swapped to hostile.")
end)

-- Gang Zone Boundary Tracking & Engine Loop
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1500)
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local foundZone = nil
        
        for _, zone in ipairs(CivilUnrest.GangZones) do
            if #(coords - zone.coords) <= zone.radius then
                foundZone = zone
                break
            end
        end
        
        if foundZone and not currentGangZone then
            currentGangZone = foundZone
            TriggerServerEvent("civilUnrest:serverZoneEntry", currentGangZone.name)
            print("[Civil Unrest | AGI-OS] Entered physical territory boundary: " .. currentGangZone.name)
        elseif not foundZone and currentGangZone then
            print("[Civil Unrest | AGI-OS] Exited physical territory boundary: " .. currentGangZone.name)
            currentGangZone = nil
        end
    end
end)

-- Dispatch Contact/Hostile AI dynamically in Zone Bounds
RegisterNetEvent("civilUnrest:triggerZoneEncounter")
AddEventHandler("civilUnrest:triggerZoneEncounter", function(zoneData, encounterType)
    Citizen.CreateThread(function()
        local modelHash = GetHashKey(zoneData.models[math.random(#zoneData.models)])
        RequestModel(modelHash)
        local timer = 0
        while not HasModelLoaded(modelHash) and timer < 50 do 
            Citizen.Wait(100) 
            timer = timer + 1
        end
        
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local spawnCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 35.0, 0.0)
        
        -- Spawn Physical AI Encounter
        local encounterPed = CreatePed(4, modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, false)
        
        if encounterType == "hostile" then
            GiveWeaponToPed(encounterPed, GetHashKey("WEAPON_MICROSMG"), 100, false, true)
            TaskCombatPed(encounterPed, playerPed, 0, 16)
            print("[Civil Unrest | AGI-OS] Local CPU computed rival gang ambush. Initiated natively.")
        else
            TaskGoToEntity(encounterPed, playerPed, -1, 3.0, 1.0, 1073741824, 0)
            print("[Civil Unrest | AGI-OS] Friendly territory contact AI approaching player for street mission operations.")
        end
    end)
end)
