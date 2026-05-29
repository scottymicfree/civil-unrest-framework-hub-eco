local UndercoverAgents = {}

-- Clean up and initialize basic economy trackers
RegisterNetEvent("civilUnrest:ecoInteract")
AddEventHandler("civilUnrest:ecoInteract", function(factionName, action)
    local src = source
    if not CivilUnrestConnectedClients[src] then return end
    
    local pedTypeChance = math.random(1, 100)
    -- Undercover Cop Check (if interacting with gang members on corners)
    if factionName and factionName ~= "LAW" and factionName ~= "CIVILIAN" and pedTypeChance <= CivilUnrest.Economy.UndercoverChance then
        -- Bust! The ped was undercover
        print("[Civil Unrest | AGI-OS] Client " .. src .. " attempted illegal commerce with an UNDERCOVER AGENT.")
        TriggerClientEvent("chat:addMessage", src, {
            color = {255, 0, 0},
            multiline = true,
            args = {"SYSTEM", "[UNDERCOVER LAPD] Freeze! You're under arrest! Action logged."}
        })
        TriggerClientEvent("civilUnrest:triggerBust", src)
        return
    end

    if action == "buy_drugs" then
        -- Logic to exchange street credit for local gang narcotics natively
        local weedBase = CivilUnrest.Economy.Drugs["weed"].basePrice
        if CivilUnrestConnectedClients[src].streetCredit >= weedBase then
            CivilUnrestConnectedClients[src].streetCredit = CivilUnrestConnectedClients[src].streetCredit - weedBase
            -- Simulated inventory handoff
            TriggerClientEvent("chat:addMessage", src, {
                color = {0, 255, 0},
                multiline = true,
                args = {"SYSTEM", "["..factionName.."] Successfully purchased Contraband for " .. weedBase .. " Street Credit."}
            })
            print("[Civil Unrest | AGI-OS] Client " .. src .. " logged standard narcotic transaction. Supply mapped natively.")
        else
            TriggerClientEvent("chat:addMessage", src, { color = {200, 0, 0}, args = {"SYSTEM", "Insufficient Street Credit for transaction."} })
        end

    elseif action == "sell_drugs" then
        -- Standard street corner dealing
        local profit = math.random(10, 45)
        CivilUnrestConnectedClients[src].streetCredit = CivilUnrestConnectedClients[src].streetCredit + profit
        TriggerClientEvent("chat:addMessage", src, {
            color = {0, 255, 0},
            multiline = true,
            args = {"SYSTEM", "["..factionName.."] Goods fenced securely. +" .. profit .. " Street Credit."}
        })
        print("[Civil Unrest | AGI-OS] Client " .. src .. " successfully injected illegal supply into dynamic cell.")

    elseif action == "buy_merch" then
        local merchData = CivilUnrest.Economy.Merchandise[factionName]
        if merchData then
            if CivilUnrestConnectedClients[src].streetCredit >= merchData.price then
                CivilUnrestConnectedClients[src].streetCredit = CivilUnrestConnectedClients[src].streetCredit - merchData.price
                TriggerClientEvent("chat:addMessage", src, {
                    color = {255, 215, 0},
                    multiline = true,
                    args = {"SYSTEM", "["..factionName.."] Purchased unique faction merchandise: " .. merchData.item .. " ("..merchData.price.." Credit)"}
                })
                -- Here we can natively trigger a client event to equip the merch if we want, or just log possession.
                TriggerClientEvent("civilUnrest:equipMerch", src, factionName, merchData.item)
                print("[Civil Unrest | AGI-OS] Faction merchandise logic executed for Client " .. src)
            else
                TriggerClientEvent("chat:addMessage", src, { color = {200, 0, 0}, args = {"SYSTEM", "Insufficient Street Credit to purchase unique merchandise."} })
            end
        end
    end
end)

RegisterNetEvent("civilUnrest:buyShopItem")
AddEventHandler("civilUnrest:buyShopItem", function(itemId, price)
    local src = source
    if CivilUnrestConnectedClients[src] and CivilUnrestConnectedClients[src].streetCredit >= price then
        CivilUnrestConnectedClients[src].streetCredit = CivilUnrestConnectedClients[src].streetCredit - price
        TriggerClientEvent("chat:addMessage", src, {
            color = {0, 255, 0},
            args = {"SYSTEM", "Bought " .. tostring(itemId) .. " for " .. tostring(price) .. " Credit."}
        })
        print("[Civil Unrest | AGI-OS] Client " .. src .. " successfully bought " .. tostring(itemId) .. " from local world shop natively.")
    else
        TriggerClientEvent("chat:addMessage", src, { color = {200, 0, 0}, args = {"SYSTEM", "Insufficient Street Credit for shop item."} })
    end
end)

RegisterNetEvent("civilUnrest:corruptCopBribe")
AddEventHandler("civilUnrest:corruptCopBribe", function()
    local src = source
    if CivilUnrestConnectedClients[src] and CivilUnrestConnectedClients[src].streetCredit >= 500 then
        CivilUnrestConnectedClients[src].streetCredit = CivilUnrestConnectedClients[src].streetCredit - 500
        -- Lower Wanted Level Natively
        TriggerClientEvent("civilUnrest:clearWantedLevel", src)
        TriggerClientEvent("chat:addMessage", src, {
            color = {50, 50, 255},
            args = {"[Corrupt LSPD]", "I didn't see anything. Now get out of my district."}
        })
    else
        TriggerClientEvent("chat:addMessage", src, { color = {200, 0, 0}, args = {"[Corrupt LSPD]", "You think that's enough? Hands behind your back!"} })
        TriggerClientEvent("civilUnrest:triggerBust", src)
    end
end)

