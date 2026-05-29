CivilUnrest = CivilUnrest or {}

-- Core Framework Settings
CivilUnrest.FrameworkName = "Civil Unrest"
CivilUnrest.DebugMode = true

-- 14 Gang Territories (San Andreas style static zones rendered natively)
CivilUnrest.Epochs = {
    CurrentMode = "TOTAL_WAR", -- "TOTAL_WAR", "SYNDICATE", "ASYLUM", "NEON_NIGHTS", "CHRONO_LOCK"
    Schedule = {
        ["Sunday"] = "ASYLUM",
        ["Monday"] = "SYNDICATE",
        ["Tuesday"] = "TOTAL_WAR",
        ["Wednesday"] = "SYNDICATE",
        ["Thursday"] = "NEON_NIGHTS",
        ["Friday"] = "CHRONO_LOCK",
        ["Saturday"] = "TOTAL_WAR"
    }
}

CivilUnrest.Cyberware = {
    ["optical_camo"] = { price = 5000, label = "Optical Camouflage (Alpha)" },
    ["reflex_booster"] = { price = 2500, label = "Reflex Booster (Speed)" },
    ["kiroshi_optics"] = { price = 1500, label = "Nightvision Optics" }
}

CivilUnrest.TurfUpgrades = {
    ["cameras"] = { price = 1000, label = "Security Cameras" },
    ["barricades"] = { price = 2000, label = "Reinforced Barricades" },
    ["drug_lab"] = { price = 5000, label = "Underground Lab" }
}

CivilUnrest.GangZones = {
    { name = "Ballas", color = 27, coords = vector3(85.0, -1958.0, 21.0), radius = 250.0, alpha = 120, models = {"g_m_y_ballaeast_01", "g_m_y_ballaorig_01", "g_m_y_ballasout_01", "g_f_y_ballas_01"} },
    { name = "Families", color = 52, coords = vector3(-176.0, -1623.0, 33.0), radius = 200.0, alpha = 120, models = {"g_m_y_famca_01", "g_m_y_famdnf_01", "g_m_y_famfor_01", "g_f_y_families_01"} },
    { name = "Vagos", color = 46, coords = vector3(335.0, -2043.0, 21.0), radius = 300.0, alpha = 120, models = {"g_m_y_mexgoon_01", "g_m_y_mexgoon_02", "g_m_y_mexgoon_03", "g_f_y_vagos_01"} },
    { name = "Lost MC", color = 3, coords = vector3(982.0, -95.0, 74.0), radius = 150.0, alpha = 120, models = {"g_m_y_lost_01", "g_m_y_lost_02", "g_m_y_lost_03", "g_f_y_lost_01"} },
    { name = "Marabunta Grande", color = 5, coords = vector3(1200.0, -1500.0, 30.0), radius = 180.0, alpha = 120, models = {"g_m_y_salvaboss_01", "g_m_y_salvagoon_01", "g_m_y_salvagoon_02", "g_m_y_salvagoon_03"} },
    { name = "Armenian Mob", color = 1, coords = vector3(-1324.0, -1350.0, 4.0), radius = 160.0, alpha = 120, models = {"g_m_m_armboss_01", "g_m_m_armgoon_01", "g_m_y_armgoon_02"} },
    { name = "Triads", color = 14, coords = vector3(-850.0, -750.0, 20.0), radius = 220.0, alpha = 120, models = {"g_m_m_chiboss_01", "g_m_m_chigoon_01", "g_m_m_chigoon_02"} },
    { name = "Aztecas", color = 38, coords = vector3(425.0, -1900.0, 25.0), radius = 180.0, alpha = 120, models = {"g_m_y_azteca_01", "u_m_y_azteca_01"} },
    { name = "Korean Mob", color = 81, coords = vector3(-730.0, -850.0, 23.0), radius = 200.0, alpha = 120, models = {"g_m_y_korean_01", "g_m_y_korean_02"} },
    { name = "Madrazo Cartel", color = 6, coords = vector3(1392.0, 1148.0, 114.0), radius = 250.0, alpha = 120, models = {"g_m_m_cartelguards_01", "g_m_m_cartelguards_02"} },
    { name = "The Professionals", color = 4, coords = vector3(930.0, -2140.0, 30.0), radius = 220.0, alpha = 120, models = {"g_m_y_pologoon_01", "g_m_y_pologoon_02"} },
    { name = "ONeil Brothers", color = 21, coords = vector3(2435.0, 4966.0, 42.0), radius = 300.0, alpha = 120, models = {"a_m_m_hillbilly_01", "a_m_m_hillbilly_02"} },
    { name = "Altruist Cult", color = 2, coords = vector3(-1170.0, 4600.0, 175.0), radius = 250.0, alpha = 120, models = {"a_m_o_acult_01", "a_m_o_acult_02", "a_m_y_acult_01", "a_m_y_acult_02"} },
    { name = "Merryweather", color = 31, coords = vector3(-2235.0, 3190.0, 32.0), radius = 350.0, alpha = 120, models = {"s_m_m_merryweather_01", "s_m_y_blackops_01", "s_m_y_blackops_02"} },
    { name = "Hood Queen", color = 61, coords = vector3(-1600.0, -1040.0, 13.0), radius = 250.0, alpha = 120, models = {"a_m_y_gay_01", "a_m_y_gay_02", "u_m_y_danceburl_01", "u_f_y_danceburl_01"} }
}

CivilUnrest.Economy = {
    Merchandise = {
        ["Ballas"] = { item = "purple_bandana", price = 50 },
        ["Families"] = { item = "green_shirt", price = 50 },
        ["Vagos"] = { item = "yellow_rag", price = 50 },
        ["Lost MC"] = { item = "leather_cut", price = 150 },
        ["Marabunta Grande"] = { item = "blue_bandana", price = 50 },
        ["Armenian Mob"] = { item = "gold_chain", price = 500 },
        ["Triads"] = { item = "dragon_tattoo_kit", price = 200 },
        ["Aztecas"] = { item = "turquoise_bandana", price = 50 },
        ["Korean Mob"] = { item = "designer_shades", price = 300 },
        ["Madrazo Cartel"] = { item = "silver_pistol_grip", price = 1000 },
        ["The Professionals"] = { item = "tactical_gloves", price = 120 },
        ["ONeil Brothers"] = { item = "moonshine_flask", price = 40 },
        ["Altruist Cult"] = { item = "cult_robe", price = 80 },
        ["Merryweather"] = { item = "pmc_cap", price = 60 },
        ["Hood Queen"] = { item = "pink_stiletto", price = 300 }
    },
    Drugs = {
        ["weed"] = { basePrice = 20 },
        ["cocaine"] = { basePrice = 80 },
        ["meth"] = { basePrice = 60 }
    },
    Cells = {
        -- Defining individual cell zones/corners for gangs where targeted commerce happens
        { gang = "Ballas", name = "Grove St Corner", coords = vector3(105.0, -1938.0, 20.0), isActive = true },
        { gang = "Families", name = "Forum Dr Corner", coords = vector3(-156.0, -1603.0, 33.0), isActive = true },
        { gang = "Vagos", name = "Rancho Projects", coords = vector3(355.0, -2023.0, 22.0), isActive = true },
        { gang = "Lost MC", name = "Stab City Trailer", coords = vector3(1002.0, -75.0, 74.0), isActive = true },
        { gang = "Hood Queen", name = "Boardwalk Corner", coords = vector3(-1600.0, -1040.0, 13.0), isActive = true },
    },
    UndercoverChance = 15 -- 15% chance a dealer is an undercover cop
}

CivilUnrest.Shops = {
    { name = "Davis Convenience", type = "store", coords = vector3(25.7, -1347.3, 29.5), radius = 10.0, items = { { item = "food", price = 10 }, { item = "water", price = 5 } } },
    { name = "Back Alley Black Market", type = "blackmarket", coords = vector3(112.5, -1972.1, 20.9), radius = 15.0, items = { { item = "lockpick", price = 250 }, { item = "burner_phone", price = 500 }, { item = "unregistered_pistol", price = 2500 } } }
}

CivilUnrest.CopDistricts = {
    { name = "Mission Row", coords = vector3(425.1, -979.5, 30.7), radius = 600.0, flavor = "professional", models = {"s_m_y_cop_01"} },
    { name = "Davis", coords = vector3(360.0, -1600.0, 29.0), radius = 400.0, flavor = "corrupt", models = {"s_m_y_cop_01", "s_m_y_sheriff_01"} },
    { name = "Sandy Shores", coords = vector3(1850.0, 3680.0, 34.0), radius = 1000.0, flavor = "brutal", models = {"s_m_y_sheriff_01"} }
}

CivilUnrest.StreetCreditLevels = {
    Novice = 0,
    Hustler = 1500,
    Kingpin = 10000
}

-- Time event settings
CivilUnrest.RiotDayOfWeek = 6 -- Saturday
CivilUnrest.NewsVanCreditTrigger = 1000 -- Threshold logic for van dispatch
