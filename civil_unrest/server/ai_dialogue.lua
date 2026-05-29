local API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key="

RegisterNetEvent("civilUnrest:generateDialogue")
AddEventHandler("civilUnrest:generateDialogue", function(pedModelHash, actionType)
    local src = source
    local apiKey = GetConvar("gemini_api_key", "")
    
    if apiKey == "" then
        print("[AGI-OS] Gemini API Key missing, utilizing local procedural generation native NLP")
        local responses = {
            chat = {"Watch your back out here, the streets are hot.", "I ain't got time for you right now.", "'Sup. Keep it moving though.", "You looking for something? Or just looking?"},
            rob = {"Please, take it all! Just don't hurt me!", "Are you crazy? The cops are right around the corner!", "Take the cash, I don't want any trouble!"},
            extort = {"Fine! Take the cut, just leave my store alone.", "You animals are bleeding us dry.", "Okay, okay, putting it in the bag right now!"},
            civ_rumors = {"I heard the Vagos are moving weight down in Rancho.", "There's an undercover setting up near the Mission Row convenience store.", "The Hood Queens are swarming the boardwalk right now.", "A supply drop went sideways near Mount Chiliad."},
            default = {"... I got nothing to say to you.", "Back off.", "Mind your business."}
        }
        
        local category = responses[actionType] or responses.default
        local fallbackDialogue = category[math.random(1, #category)]
        TriggerClientEvent("civilUnrest:receiveDialogue", src, fallbackDialogue)
        return
    end

    local credit = CivilUnrestConnectedClients[src] and CivilUnrestConnectedClients[src].streetCredit or 0
    local riotStatus = CivilUnrestServerState.isRiotActive and "A city-wide violent weekly riot is currently underway." or "The streets are relatively quiet right now."

    local promptText = string.format([[
You are an NPC residing in a gritty GTA5 FiveM gang server world.
The player has engaged you with the action: "%s".
Player's current street credit: %s (determines how much you respect them).
Current city status: %s
NPC Model Hash: %s

Respond strictly in character, as an NPC in this gritty world. Limit your response to 1 or 2 spoken sentences. Do not use asterisks for actions. Do not provide a JSON block, just the raw text of what you say.
]], actionType, credit, riotStatus, pedModelHash)

    local payload = {
        contents = {
            {
                role = "user",
                parts = {
                    { text = promptText }
                }
            }
        }
    }

    PerformHttpRequest(API_URL .. apiKey, function(statusCode, responseText, headers)
        if statusCode == 200 then
            local data = json.decode(responseText)
            if data and data.candidates and data.candidates[1] and data.candidates[1].content and data.candidates[1].content.parts and data.candidates[1].content.parts[1] then
                local dialogue = data.candidates[1].content.parts[1].text
                TriggerClientEvent("civilUnrest:receiveDialogue", src, dialogue)
            else
                TriggerClientEvent("civilUnrest:receiveDialogue", src, "SYSTEM: Failed to parse AI Response.")
            end
        else
            TriggerClientEvent("civilUnrest:receiveDialogue", src, "SYSTEM: AI Communications Server Offline. Code: " .. tostring(statusCode))
        end
    end, "POST", json.encode(payload), { ["Content-Type"] = "application/json" })
end)
