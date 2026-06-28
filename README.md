# 🎲 Aura RNG

A Roblox RNG game in the style of *Sol's RNG*. Roll the dice, discover **auras**
ranging from **1 in 2** all the way to **1 in 1 Quadrillion**, climb the luck
ladder with potions and Robux capsules, equip your rarest aura as a glowing
effect, and **trade** with other players in the Trading Plaza.

---

## ✨ Features

### 🎲 Rolling
- A big **Roll Dice** button (also bound to **Space**) with a cooldown ring.
- **50 auras** spanning the full rarity range — `1 in 2` → `1 in 1Q`, grouped
  into 11 tiers: Common, Uncommon, Rare, Epic, Legendary, Mythic, Exotic,
  Divine, Celestial, Transcendent, **Quantum**.
- A suspenseful **reveal animation** — rarer auras get a longer spin and a
  screen flash. New discoveries show a ✨ NEW ✨ tag.
- **Luck** system: luck performs extra draws and keeps the rarest, so boosts
  meaningfully improve your odds at top-tier auras.
- Your rarest equipped aura becomes a **glowing particle effect** on your
  character.

### 🌐 "How many exist"
Every aura tracks a **global existence counter** — how many have ever been
rolled across all servers (merged on save). Browse them all in the **Aura
Index**, which shows each aura's rarity, exist count, and your discovery
progress.

### 🛒 Shops
- **Potion Shop** (coins): luck potions (x2 / x5 / x15) and a Haste potion that
  speeds up rolling. Active potions show a live countdown.
- **Capsule Shop** (Robux *or* coins): six capsules — Basic, Lucky, Mythic,
  Celestial, Transcendent, and a **Mega 10x** capsule that pulls ten
  luck-boosted auras at once.
- **Gamepasses**: Fast Roll, Lucky II, Auto Roll, VIP.
- **Coin packs** (Robux developer products).

### 🤝 Trading
- Walk up to another player in the **Trading Plaza** and send a trade invite.
- A full trade window: your offer vs. theirs, add/remove auras from your
  inventory, **both must confirm**, and a safety countdown completes the swap
  atomically (re-validated server-side so nothing can be duplicated).

### 🗺️ World
Procedurally built at runtime (no external assets):
- A neon **spawn island** with a glowing **Roll Altar** centerpiece.
- Podiums signposting the Shop, Capsules, Index, and Trading Plaza.
- A separate raised **Trading Plaza** with trade pads.
- Night atmosphere with fog, bloom, and a starfield so the neon pops.

### 🎨 UI
A consistent, professional GUI suite — themed components, gradients, hover
feedback, modal windows, toast notifications, and an emoji icon for every
action (🎲 roll, 🎒 inventory, 🛒 shop, 🎁 capsules, 📖 index, 🤝 trade).

---

## 🛠️ Setup

### 1. Configure your ids
Open `src/ReplicatedStorage/GameConfig.lua` and:
- Add your Roblox **UserId** to `GameConfig.Admins` (unlocks `/give <amount>`
  and `/luck <amount>` chat commands for testing).
- Paste your **gamepass ids** into `GameConfig.Monetization.Gamepasses`.
- Paste your **developer-product ids** into `GameConfig.Monetization.Products`.

Open `src/ReplicatedStorage/CapsuleData.lua` and paste a developer-product
`productId` for each capsule you want to sell for Robux. (Capsules with a
`coinPrice` can also be bought with in-game coins immediately.)

> Placeholder ids are `0`. Anything left at `0` simply won't prompt a purchase —
> the game runs fine without them; you just won't be able to buy that item.

### 2. Sync with Rojo
```bash
rojo serve default.project.json
```
Connect from Roblox Studio via the Rojo plugin.

### 3. Publish
Enable **Studio Access to API Services** (for DataStores) and hit **Play**, or
publish the place to Roblox.

---

## 📁 Project structure
```
src/
├── ReplicatedStorage/          # shared modules (server + client)
│   ├── GameConfig.lua          # all tunables, monetization ids, admins
│   ├── AuraData.lua            # the 50 auras + roll/luck logic
│   ├── CapsuleData.lua         # Robux capsules and their aura pools
│   ├── ShopData.lua            # coin-shop potions
│   ├── Util.lua                # number/rarity formatting helpers
│   └── Remotes.lua             # single source of truth for remote names
│
├── ServerScriptService/
│   ├── Core.lua                # state: profiles, DataStore, remotes, globals
│   ├── MainServer.server.lua   # bootstrap, gamepasses, daily bonus, admin
│   ├── RollSystem.server.lua   # roll requests → aura, coins, global counts
│   ├── ShopSystem.server.lua   # equip/sell, potions, capsules, receipts
│   ├── TradeSystem.server.lua  # player-to-player trading
│   └── MapBuilder.server.lua   # builds the world at runtime
│
└── StarterPlayer/StarterPlayerScripts/
    ├── Client.client.lua       # bootstrap: ctx, profile state, window registry
    └── UI/                     # ModuleScripts, one per screen
        ├── Theme.lua  Components.lua  AuraCard.lua
        ├── Notifications.lua  MainHUD.lua  RollReveal.lua
        └── Inventory.lua  Shop.lua  Capsules.lua  Index.lua  Trade.lua
```

---

## ⚙️ Tuning ideas
- Add more auras: append to the list in `AuraData.lua` (ids are append-stable).
- Change roll speed / cooldowns and luck ceilings in `GameConfig.lua`.
- Adjust capsule luck and pools in `CapsuleData.lua`.
- The world is data-light — tweak `MapBuilder.server.lua` to redesign the map.
