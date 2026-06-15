-- Take & Brainrot | AdminConfig
-- All admin commands and permission tiers

local AdminConfig = {}

-- Permission levels
AdminConfig.Levels = {
    Player  = 0,
    Mod     = 1,
    Admin   = 2,
    Owner   = 3,
}

-- Every command: { level required, description }
AdminConfig.Commands = {
    -- Moderation
    ["kick"]        = { level = AdminConfig.Levels.Mod,   desc = "Kick a player. Usage: !kick <name> [reason]" },
    ["ban"]         = { level = AdminConfig.Levels.Admin, desc = "Ban a player. Usage: !ban <name> [reason]" },
    ["unban"]       = { level = AdminConfig.Levels.Admin, desc = "Unban a player. Usage: !unban <name>" },
    ["mute"]        = { level = AdminConfig.Levels.Mod,   desc = "Mute a player. Usage: !mute <name>" },
    ["unmute"]      = { level = AdminConfig.Levels.Mod,   desc = "Unmute a player. Usage: !unmute <name>" },
    ["warn"]        = { level = AdminConfig.Levels.Mod,   desc = "Warn a player. Usage: !warn <name> <reason>" },

    -- Movement / Position
    ["teleport"]    = { level = AdminConfig.Levels.Mod,   desc = "Teleport to a player. Usage: !teleport <name>" },
    ["bring"]       = { level = AdminConfig.Levels.Mod,   desc = "Bring a player to you. Usage: !bring <name>" },
    ["fling"]       = { level = AdminConfig.Levels.Admin, desc = "Fling a player. Usage: !fling <name>" },
    ["freeze"]      = { level = AdminConfig.Levels.Mod,   desc = "Freeze a player. Usage: !freeze <name>" },
    ["unfreeze"]    = { level = AdminConfig.Levels.Mod,   desc = "Unfreeze a player. Usage: !unfreeze <name>" },
    ["goto"]        = { level = AdminConfig.Levels.Mod,   desc = "Go to a player. Usage: !goto <name>" },

    -- Appearance abuse
    ["invisible"]   = { level = AdminConfig.Levels.Admin, desc = "Make a player invisible. Usage: !invisible <name>" },
    ["visible"]     = { level = AdminConfig.Levels.Admin, desc = "Make a player visible. Usage: !visible <name>" },
    ["giant"]       = { level = AdminConfig.Levels.Admin, desc = "Make a player giant. Usage: !giant <name>" },
    ["tiny"]        = { level = AdminConfig.Levels.Admin, desc = "Make a player tiny. Usage: !tiny <name>" },
    ["normalsize"]  = { level = AdminConfig.Levels.Admin, desc = "Reset a player's size. Usage: !normalsize <name>" },
    ["speed"]       = { level = AdminConfig.Levels.Admin, desc = "Set walkspeed. Usage: !speed <name> <value>" },
    ["jump"]        = { level = AdminConfig.Levels.Admin, desc = "Set jump power. Usage: !jump <name> <value>" },
    ["noclip"]      = { level = AdminConfig.Levels.Admin, desc = "Toggle noclip. Usage: !noclip <name>" },
    ["sparkles"]    = { level = AdminConfig.Levels.Admin, desc = "Add sparkles. Usage: !sparkles <name>" },
    ["fire"]        = { level = AdminConfig.Levels.Admin, desc = "Set player on fire. Usage: !fire <name>" },
    ["smoke"]       = { level = AdminConfig.Levels.Admin, desc = "Add smoke. Usage: !smoke <name>" },

    -- Kill / Respawn
    ["kill"]        = { level = AdminConfig.Levels.Admin, desc = "Kill a player. Usage: !kill <name>" },
    ["respawn"]     = { level = AdminConfig.Levels.Admin, desc = "Respawn a player. Usage: !respawn <name>" },
    ["god"]         = { level = AdminConfig.Levels.Admin, desc = "Make a player invincible. Usage: !god <name>" },
    ["ungod"]       = { level = AdminConfig.Levels.Admin, desc = "Remove invincibility. Usage: !ungod <name>" },

    -- Economy
    ["addpoints"]   = { level = AdminConfig.Levels.Admin, desc = "Give points. Usage: !addpoints <name> <amount>" },
    ["removepoints"]= { level = AdminConfig.Levels.Admin, desc = "Remove points. Usage: !removepoints <name> <amount>" },
    ["setpoints"]   = { level = AdminConfig.Levels.Owner, desc = "Set points. Usage: !setpoints <name> <amount>" },

    -- Events
    ["event"]       = { level = AdminConfig.Levels.Admin, desc = "Start an event. Usage: !event <name>" },
    ["stopevent"]   = { level = AdminConfig.Levels.Admin, desc = "Stop current event. Usage: !stopevent" },

    -- Server
    ["shutdown"]    = { level = AdminConfig.Levels.Owner, desc = "Shutdown server. Usage: !shutdown" },
    ["announce"]    = { level = AdminConfig.Levels.Mod,   desc = "Send announcement. Usage: !announce <message>" },
    ["pm"]          = { level = AdminConfig.Levels.Mod,   desc = "Private message. Usage: !pm <name> <message>" },

    -- Conveyor
    ["conveyorspeed"]= { level = AdminConfig.Levels.Admin, desc = "Set conveyor speed. Usage: !conveyorspeed <value>" },
    ["spawnalleggs"] = { level = AdminConfig.Levels.Admin, desc = "Spawn all egg types. Usage: !spawnalleggs" },
    ["clearconveyor"]= { level = AdminConfig.Levels.Admin, desc = "Clear all eggs on belt. Usage: !clearconveyor" },

    -- Misc abuse
    ["loopkill"]    = { level = AdminConfig.Levels.Admin, desc = "Loop kill a player. Usage: !loopkill <name>" },
    ["stoploopkill"]= { level = AdminConfig.Levels.Admin, desc = "Stop loop killing. Usage: !stoploopkill <name>" },
    ["explode"]     = { level = AdminConfig.Levels.Admin, desc = "Explode a player. Usage: !explode <name>" },
    ["rocket"]      = { level = AdminConfig.Levels.Admin, desc = "Launch player like a rocket. Usage: !rocket <name>" },
    ["dance"]       = { level = AdminConfig.Levels.Admin, desc = "Force a player to dance. Usage: !dance <name>" },
    ["sit"]         = { level = AdminConfig.Levels.Mod,   desc = "Force a player to sit. Usage: !sit <name>" },
    ["headless"]    = { level = AdminConfig.Levels.Admin, desc = "Make player headless. Usage: !headless <name>" },
    ["hat"]         = { level = AdminConfig.Levels.Admin, desc = "Give random hat. Usage: !hat <name>" },
    ["rainbow"]     = { level = AdminConfig.Levels.Admin, desc = "Rainbow body color. Usage: !rainbow <name>" },

    -- Info
    ["cmds"]        = { level = AdminConfig.Levels.Player, desc = "List all available commands." },
    ["admins"]      = { level = AdminConfig.Levels.Player, desc = "List online admins." },
    ["info"]        = { level = AdminConfig.Levels.Player, desc = "Show game info." },
    ["ping"]        = { level = AdminConfig.Levels.Player, desc = "Check your ping." },
}

return AdminConfig
