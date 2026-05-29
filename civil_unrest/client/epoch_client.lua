_G.CurrentEpoch = "TOTAL_WAR"
local InfectionLevel = 0
local HasCyberware = {}

RegisterNetEvent("civilUnrest:syncEpoch")
AddEventHandler("civilUnrest:syncEpoch", function(epochStr)
    _G.CurrentEpoch = epochStr
    print("[Civil Unrest | AGI-OS] Epoch synchronized to: " .. _G.CurrentEpoch)
    
    -- Handle Environmental Overhaul Based on Epoch
    if _G.CurrentEpoch == "ASYLUM" then
        SetWeatherTypePersist("SMOG")
        SetWeatherTypeNowPersist("SMOG")
        SetTimecycleModifier("drug_flying_base")
        SendNUIMessage({ type = "UPDATE_DIALOGUE", text = "[SYSTEM] Bioweapon Outbreak Detected. Survive." })
    elseif _G.CurrentEpoch == "NEON_NIGHTS" or _G.CurrentEpoch == "CHRONO_LOCK" then
        SetWeatherTypePersist("CLEAR")
        SetWeatherTypeNowPersist("CLEAR")
        NetworkOverrideClockTime(23, 0, 0)
        SetTimecycleModifier("MP_screen_flare")
        SendNUIMessage({ type = "UPDATE_DIALOGUE", text = "[SYSTEM] Booting CyberOS... Welcome to 2077." })
    else
        ClearTimecycleModifier()
        ClearWeatherTypePersist()
    end
end)

Citizen.CreateThread(function()
    TriggerServerEvent("civilUnrest:requestEpochSync")
    while true do
        Citizen.Wait(1000)
        local ped = PlayerPedId()

        -- "The Asylum" Dynamic Infection & Zombies
        if _G.CurrentEpoch == "ASYLUM" then
            InfectionLevel = InfectionLevel + 1
            if InfectionLevel > 1500 and not IsEntityDead(ped) then
                -- Player gets infected dynamically
                ApplyDamageToPed(ped, 10, false)
                SetPedMovementClipset(ped, "move_m@drunk@verydrunk", 1.0)
            end
            
            -- Turn nearby peds into Zombies natively if dead or near
            local peds = GetGamePool('CPed')
            for _, zPed in ipairs(peds) do
                if not IsPedAPlayer(zPed) and not IsPedDeadOrDying(zPed, 1) then
                    if not IsPedInCombat(zPed, 0) then
                        TaskCombatPed(zPed, ped, 0, 16)
                    end
                end
            end
        end

        -- "Neon Nights 2077" Cyberware Overrides
        if _G.CurrentEpoch == "NEON_NIGHTS" or _G.CurrentEpoch == "CHRONO_LOCK" then
            if HasCyberware["reflex_booster"] then
                SetRunSprintMultiplierForPlayer(PlayerId(), 1.49)
            else
                SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
            end
            
            if HasCyberware["kiroshi_optics"] then
                SetNightvision(true)
            end
        end
    end
end)

-- NUI Hook for taking actions based on Epoch Modes
RegisterNetEvent("civilUnrest:installCyberware")
AddEventHandler("civilUnrest:installCyberware", function(implant)
    if _G.CurrentEpoch == "NEON_NIGHTS" then
        HasCyberware[implant] = true
        print("[Civil Unrest | AGI-OS] Cyberware Installed: " .. implant)
    end
end)
