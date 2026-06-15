# 🎮 Take & Brainrot

A Roblox game featuring eggs on a conveyor belt, wild events, a full admin panel, and admin abuse commands.

---

## Features

### 🥚 Conveyor Belt
- 5 egg types: Normal, Golden, Rainbow, Brainrot, Diamond
- Weighted random spawning — rarer eggs appear less often
- Touch to collect for points
- Adjustable speed via `!conveyorspeed <value>`

### ⚡ Events (auto + admin-triggered)
| Event | Description |
|---|---|
| ☄️ Meteor Shower | Fireballs rain from the sky with explosions |
| 🌊 Flood | Water rises slowly then drains |
| 🌍 Earthquake | Players get shaken violently |
| 🧠 Fog of Brainrot | Heavy purple fog, can barely see |
| 🥚 Egg Rain | Hundreds of collectible eggs fall from the sky |
| ⬆️ Gravity Flip | Gravity reverses for everyone |
| ⚡ Speed Boost | Everyone gets 80 walkspeed |

### 😈 Admin Panel
Press **F2** or click **⚙️ Admin** in the top-right corner.

Tabs: **Players · Appearance · Events · Abuse · Server**

---

## Admin Commands (chat prefix `!`)

### Moderation
`!kick` `!ban` `!mute` `!unmute` `!warn`

### Movement
`!teleport` `!bring` `!goto` `!fling` `!freeze` `!unfreeze` `!rocket`

### Appearance
`!giant` `!tiny` `!normalsize` `!invisible` `!visible` `!rainbow` `!headless` `!fire` `!smoke` `!sparkles`

### Kill / God
`!kill` `!respawn` `!god` `!ungod` `!loopkill` `!stoploopkill`

### Stats
`!speed <name> <val>` `!jump <name> <val>` `!addpoints` `!removepoints` `!setpoints`

### Events
`!event <name>` `!stopevent`

### Conveyor
`!conveyorspeed <val>` `!spawnalleggs` `!clearconveyor`

### Abuse Specials (Admin+)
`!catapultall` `!disco` `!discooff` `!partbomb <count>` `!sizewave` `!chaos` `!headlessall` `!speedburst` `!gravitychaos` `!noclip`

### Server
`!announce <msg>` `!pm <name> <msg>` `!shutdown`

### Info (everyone)
`!cmds` `!admins` `!info` `!ping`

---

## Setup

### 1. Add admins
Edit `src/ReplicatedStorage/GameConfig.lua`:
```lua
GameConfig.Admin.Admins = { 12345678 }   -- your Roblox UserId
GameConfig.Admin.Owners = { 87654321 }
```

### 2. Import with Rojo
```bash
rojo serve default.project.json
```
Then connect in Roblox Studio via the Rojo plugin.

### 3. Play
Hit **Play** in Studio or publish to Roblox!

---

## File Structure
```
src/
├── ServerScriptService/
│   ├── MainGame.server.lua        # Player data, points, remotes
│   ├── AdminSystem.server.lua     # All admin commands (chat + remote)
│   ├── ConveyorSystem.server.lua  # Egg conveyor belt
│   ├── EventsSystem.server.lua    # All 7 events
│   └── AdminAbuse.server.lua      # Extra chaos tools
├── ReplicatedStorage/
│   ├── GameConfig.lua             # All tunable settings
│   └── AdminConfig.lua            # Commands & permission levels
├── StarterGui/
│   ├── AdminPanel/AdminPanel.lua  # Drag-able GUI panel (F2)
│   └── EventsGui/EventsGui.lua    # Event countdown HUD
└── StarterPlayer/StarterPlayerScripts/
    └── LocalAdmin.client.lua      # Notifications, HUD, banners
```
