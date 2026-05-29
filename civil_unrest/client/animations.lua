-- Custom Player Animations & Interactions
-- Handles crouching, leaning, and gestures for stealth and NPC interactions.

local isCrouched = false
local isLeaning = false
local currentGesture = nil

-- Dictionary loading helper
local function loadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(100)
    end
end

-- Keybinds and Polling
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()

        -- Disable default stealth (CTRL) so we can override it naturally
        DisableControlAction(0, 36, true) 

        -- Toggle Crouch (Left Ctrl)
        if IsDisabledControlJustPressed(0, 36) then
            if not IsPedInAnyVehicle(ped, false) and not IsPedFalling(ped) then
                if isCrouched then
                    ResetPedMovementClipset(ped, 0)
                    isCrouched = false
                else
                    RequestAnimSet("move_ped_crouched")
                    while not HasAnimSetLoaded("move_ped_crouched") do
                        Citizen.Wait(100)
                    end
                    SetPedMovementClipset(ped, "move_ped_crouched", 0.5)
                    isCrouched = true
                end
            end
        end

        -- Toggle Leaning (Command mapping usually, but we'll bind to 'E' contextually or a command)
        -- We'll just define the commands for animations so users can bind them.
    end
end)

-- Gestures and Scenarios
RegisterCommand("lean", function(source, args)
    local ped = PlayerPedId()
    if isLeaning then
        ClearPedTasks(ped)
        isLeaning = false
    else
        TaskStartScenarioInPlace(ped, "WORLD_HUMAN_LEANING", 0, true)
        isLeaning = true
    end
end, false)

RegisterCommand("surrender", function()
    local ped = PlayerPedId()
    local dict = "random@arrests"
    local anim = "idle_2_hands_up"
    
    if IsEntityPlayingAnim(ped, dict, anim, 3) then
        ClearPedTasks(ped)
    else
        loadAnimDict(dict)
        TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 50, 0, false, false, false)
    end
end, false)

RegisterCommand("point", function()
    local ped = PlayerPedId()
    local dict = "anim@mp_point"
    local anim = "idle_2_hands_up"
    
    if IsEntityPlayingAnim(ped, dict, "idle", 3) then
        ClearPedTasks(ped)
    else
        loadAnimDict(dict)
        TaskPlayAnim(ped, dict, "idle", 8.0, 8.0, 3000, 50, 0, false, false, false)
    end
end, false)

-- Exports / Events for context menu (Radial Menu) integration
RegisterNetEvent("civilUnrest:playGesture")
AddEventHandler("civilUnrest:playGesture", function(gesture)
    local ped = PlayerPedId()
    if gesture == "greet" then
        local dict = "gestures@m@standing@casual"
        loadAnimDict(dict)
        TaskPlayAnim(ped, dict, "gesture_hello", 8.0, 8.0, -1, 48, 0, false, false, false)
    elseif gesture == "intimidate" then
        local dict = "amb@world_human_muscle_flex@male@base"
        loadAnimDict(dict)
        TaskPlayAnim(ped, dict, "base", 8.0, 8.0, -1, 48, 0, false, false, false)
    end
end)
