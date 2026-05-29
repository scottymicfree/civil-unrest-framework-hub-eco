-- Epoch / Theme System Manager for AGI-OS FiveM

local ActiveEpoch = CivilUnrest.Epochs.CurrentMode

RegisterNetEvent("civilUnrest:requestEpochSync")
AddEventHandler("civilUnrest:requestEpochSync", function()
    TriggerClientEvent("civilUnrest:syncEpoch", source, ActiveEpoch)
end)

RegisterCommand("setepoch", function(source, args)
    if source == 0 or (CivilUnrestConnectedClients[source] and CivilUnrestConnectedClients[source].streetCredit > 0) then -- Admin check proxy
        local newEpoch = args[1]
        if newEpoch then
            ActiveEpoch = newEpoch
            TriggerClientEvent("civilUnrest:syncEpoch", -1, ActiveEpoch)
            print("[Civil Unrest | AGI-OS] Global Epoch shifted to " .. ActiveEpoch)
        end
    end
end, true)

-- Syndicate Stock Market Actions
RegisterNetEvent("civilUnrest:stockTakeover")
AddEventHandler("civilUnrest:stockTakeover", function(targetCompany)
    local src = source
    if CivilUnrestConnectedClients[src] then
        -- Corporate RP: Spend massive credit to execute takeover
        if CivilUnrestConnectedClients[src].streetCredit >= 100000 then
            CivilUnrestConnectedClients[src].streetCredit = CivilUnrestConnectedClients[src].streetCredit - 100000
            TriggerClientEvent("chat:addMessage", -1, {
                color = {255, 0, 0},
                multiline = true,
                args = {"WALL STREET", "A hostile takeover of " .. targetCompany .. " was initiated. Market fluctuates!"}
            })
        else
            TriggerClientEvent("chat:addMessage", src, { color = {200, 0, 0}, args = {"SYSTEM", "Insufficient Street Credit for a Corporate Takeover."} })
        end
    end
end)

-- Turf War Upgrades
RegisterNetEvent("civilUnrest:buyTurfUpgrade")
AddEventHandler("civilUnrest:buyTurfUpgrade", function(zoneName, upgradeId)
    local src = source
    local upgrade = CivilUnrest.TurfUpgrades[upgradeId]
    if upgrade and CivilUnrestConnectedClients[src] then
        if CivilUnrestConnectedClients[src].streetCredit >= upgrade.price then
            CivilUnrestConnectedClients[src].streetCredit = CivilUnrestConnectedClients[src].streetCredit - upgrade.price
            TriggerClientEvent("chat:addMessage", src, { color = {0, 255, 0}, args = {"SYSTEM", "Purchased " .. upgrade.label .. " for " .. zoneName .. " HQ."} })
            print("[Civil Unrest | AGI-OS] Turf upgraded natively for " .. zoneName)
        else
            TriggerClientEvent("chat:addMessage", src, { color = {200, 0, 0}, args = {"SYSTEM", "Insufficient Credit."} })
        end
    end
end)
