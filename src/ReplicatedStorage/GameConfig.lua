-- Take & Brainrot | GameConfig
-- Central configuration for the entire game

local GameConfig = {}

GameConfig.GAME_NAME = "Take & Brainrot"
GameConfig.VERSION = "1.0.0"

-- Conveyor Settings
GameConfig.Conveyor = {
    Speed = 16,              -- studs per second
    EggSpawnInterval = 3,    -- seconds between egg spawns
    EggTypes = {
        { name = "Normal Egg",      color = Color3.fromRGB(255, 255, 200), weight = 50, value = 10  },
        { name = "Golden Egg",      color = Color3.fromRGB(255, 200, 0),   weight = 20, value = 50  },
        { name = "Rainbow Egg",     color = Color3.fromRGB(200, 0, 255),   weight = 10, value = 100 },
        { name = "Brainrot Egg",    color = Color3.fromRGB(0, 255, 100),   weight = 15, value = 75  },
        { name = "Diamond Egg",     color = Color3.fromRGB(100, 220, 255), weight = 5,  value = 500 },
    },
    MaxEggsOnBelt = 12,
}

-- Events Settings
GameConfig.Events = {
    CooldownTime = 120,   -- seconds between events
    Duration = {
        MeteorShower = 30,
        Flood        = 45,
        Earthquake   = 20,
        FogOfBrainrot = 60,
        EggRain      = 40,
        GravityFlip  = 35,
        SpeedBoost   = 30,
    },
}

-- Admin Settings
GameConfig.Admin = {
    -- Add Roblox UserIds of admins here
    Admins = {
        0,            -- placeholder: replace with real UserId
    },
    -- Owners have all powers
    Owners = {
        0,            -- placeholder: replace with real UserId
    },
    CommandPrefix = "!",
    AbuseLogEnabled = true,
}

-- Points & Economy
GameConfig.Economy = {
    PickupEggBonus = 5,
    EventParticipationBonus = 25,
    DailyLoginBonus = 100,
}

return GameConfig
