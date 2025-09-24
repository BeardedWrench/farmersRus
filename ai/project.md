LÖVR 3D Farming Game (Desktop Only, DDD Entities, ECS)

Act as a senior game engineer. Build a production-grade, well-documented LÖVR (Lua) project for a cozy, low-poly 3D farming game (perspective camera, city-builder style—no player avatar movement). Use a custom ECS and a Domain-Driven Design folder layout. Every in-game thing (crops, tools, props, shops, fences, compost bin, etc.) is an entity domain with its own code and assets under entities/<domain>/....

Reference
	•	LÖVR Getting Started: https://lovr.org/docs/Getting_Started
	•	LÖVR Graphics & Model APIs (for loading models, nodes/sockets, etc.): https://lovr.org/docs/lovr.graphics and https://lovr.org/docs/Model

⸻

Game Goals (Desktop Only)
	•	Perspective camera with smooth orbit / pan / zoom.
	•	Grid building with colored cell highlights (green valid, red blocked, yellow occupied, blue preview).
	•	Tools-as-cursor: shovel (till), watering can (tilts toward cursor + water particles), seed tool, harvest tool.
	•	Crops with growth stages (e.g., Corn stage 1–4). Stage 4 has named sockets where fruit models (e.g., corn cobs) attach dynamically.
	•	Plant stats: growthSpeed, hydration, health, fertilizer; watering darkens soil; fertilizer/compost boosts growth.
	•	Economy: shops to buy seeds/tools/fertilizer; sell harvested crops for money.
	•	Inventory: starter tools+seeds+money; item stacks.
	•	Scenes: Farm (main) and Town (shops + ambient NPCs). HUD button to travel with a short fade transition.
	•	UI: cozy/rounded vibe; HUD, inventory, shop, pause, settings.
	•	Audio: ambient farm loop, soft piano music, UI clicks, tool SFX, watering SFX.
	•	Save/Load: JSON save of entities/components/inventory/money/time.

⸻

Architecture
	•	Custom ECS (no external deps): Entities are integer IDs. Components are plain Lua tables. Systems register queries and implement update(dt) and optional draw(pass).
	•	DDD layout: Each domain (entity type) encapsulates its prefab(s), components specific to the domain, and its art (models/materials/textures/sfx) inside entities/<domain>/.
	•	Global modules live under /core, /systems, /ui, /scene, /fx, /gameplay, /io.
	•	Global/shared assets live under /assets/* (fonts, shared textures, global SFX/music, generic materials, shared models).
Entity-unique art belongs under that entity’s folder.

Detailed Folder Structure (DDD + ECS)
```
  conf.lua
  main.lua
  README.md

  /core/                          -- engine-like infrastructure
    ecs.lua                       -- entity registry, add/get/remove, system scheduler
    events.lua                    -- pub/sub
    time.lua                      -- clocks, day/night ticks (if needed later)
    util.lua                      -- math, table helpers, ray/grid helpers
    input.lua                     -- keyboard/mouse handling
    resources.lua                 -- loaders (models/materials/textures/sfx), caches

  /systems/                       -- cross-domain behavior
    camera_system.lua
    grid_system.lua               -- grid gen, snapping, occupancy, highlight state
    placement_system.lua          -- validates placement, shows ghost, color states
    tool_system.lua               -- shovel/water/seed/harvest behaviors
    crop_growth_system.lua        -- growth, stage transitions, fruit socket attach
    hydration_system.lua
    fertility_system.lua          -- compost/manure effects
    harvest_system.lua
    inventory_system.lua
    economy_system.lua
    ui_system.lua
    audio_system.lua
    scene_system.lua              -- transitions, fade in/out
    save_system.lua
    render_system.lua
    fx_system.lua                 -- particles (water, harvest sparkle)

  /components/                    -- reusable, generic components
    transform.lua                 -- position/rotation/scale
    renderable.lua                -- model ref, material, tint, visibility
    gridcell.lua                  -- x,y cell + occupancy flags
    placeable.lua                 -- placement rules, cost
    soil.lua                      -- tilled, wetness, darken timer
    crop.lua                      -- {type, stage, progress, stats={growth,hydration,health,fertilizer}}
    sockets.lua                   -- nodeName -> attached entity id(s)
    tool.lua                      -- type: shovel|watering|seed|harvest
    cursor.lua                    -- hover cell, current tool, preview state
    inventory.lua                 -- item stacks
    wallet.lua                    -- money
    shop.lua                      -- stock list, prices, category
    compost.lua                   -- input items, progress, output fertilizer
    ambient.lua                   -- non-interactive props/NPCs
    audio_emitter.lua             -- 2D/positional flags, source handles

  /entities/                      -- DDD: each domain contains its code + assets
    /corn/
      corn.lua                    -- Prefabs/constructors: CornPlant(), CornFruit()
      config.lua                  -- stages, thresholds, growth tuning, sell price
      sockets.lua                 -- names, rules for fruit attach points
      /models/
        stage_1.fbx
        stage_2.fbx
        stage_3.fbx
        stage_4.fbx               -- contains nodes: Socket_CornA, Socket_CornB, ...
        fruit_cob.fbx
      /materials/
        corn_stalk.mat.lua        -- material defs loaded/applied at runtime
        corn_cob.mat.lua
      /textures/
        corn_stalk_albedo.png
        corn_cob_albedo.png
      /sfx/
        rustle.wav                 -- optional plant-specific SFX

    /wheat/                       -- (example future crop, same pattern)
      wheat.lua
      config.lua
      sockets.lua
      /models/ ...                -- stages + fruit
      /materials/ ...
      /textures/ ...
      /sfx/ ...

    /soil/
      soil.lua                    -- SoilTile() prefab, tilled/unt-tilled variants
      /models/
        soil_tile.fbx
        soil_tile_tilled.fbx
      /materials/
        soil_dry.mat.lua
        soil_wet.mat.lua
      /textures/
        soil_dry_albedo.png
        soil_wet_albedo.png

    /fence/
      fence.lua                   -- FenceSegment(), rules to expand boundary
      /models/
        fence_straight.fbx
        fence_corner.fbx
      /materials/...
      /textures/...

    /compost_bin/
      compost_bin.lua             -- CompostBin() prefab; converts inputs → fertilizer
      /models/ compost_bin.fbx
      /materials/...
      /textures/...
      /sfx/  compost_start.wav compost_ready.wav

    /tools/
      shovel.lua                  -- ShovelTool()
      watering_can.lua            -- WateringCanTool() (cursor tilt + particle params)
      seed_bag.lua                -- SeedTool(cropType)
      harvest_tool.lua            -- HarvestTool()
      /models/
        shovel.fbx
        watering_can.fbx
        seed_bag.fbx
        sickle.fbx
      /materials/...
      /textures/...
      /sfx/
        shovel_dig.wav
        water_pour.wav
        harvest.wav

    /shops/
      seed_shop.lua               -- SeedShop() inventory from gameplay/shop_db.lua
      tool_shop.lua               -- ToolShop()
      sell_stand.lua              -- SellStand() accepts crops, pays wallet
      /models/ seed_shop.fbx tool_shop.fbx sell_stand.fbx
      /materials/...
      /textures/...
      /sfx/  buy.wav sell.wav

    /props_town/
      bench.lua crate.lua lamp.lua planter.lua npc_dummy.lua
      /models/ ...
      /materials/...
      /textures/...

  /scene/
    manager.lua                   -- push/pop Farm/Town, transition API
    farm.lua
    town.lua

  /ui/
    theme.lua                     -- colors, radius, paddings, fonts, SFX mapping
    widgets.lua                   -- panel, button, tooltip, list, sliders, tabs
    hud.lua                       -- tool hotbar, money, grid tooltip, “Travel to Town”
    menus.lua                     -- main, pause, settings
    inventory.lua                 -- inventory window
    shop.lua                      -- buy/sell dialogs

  /gameplay/
    crops_db.lua                  -- registry of crop domains (corn, wheat, tomato…)
    shop_db.lua                   -- stock & prices for shops
    balance.lua                   -- costs, sell prices, tuning constants
    starter_pack.lua              -- initial inventory & wallet

  /fx/
    particles.lua                 -- basic particle system
    water_spray.lua               -- defines emitter settings for watering
    sparkle.lua                   -- harvest sparkle effect

  /assets/                        -- global/shared assets (non-entity-specific)
    /models/  grid_cursor.fbx ghost_cube.fbx
    /materials/  ui_card.mat.lua ghost_preview.mat.lua
    /textures/  ui_panel.png checker.png
    /sfx/  ui_click.wav ui_open.wav ui_close.wav ambient_farm.wav
    /music/  cozy_piano.ogg
    /fonts/  Comfortaa.ttf

  /io/
    save.lua                      -- JSON save/load, schema versioning
```
Naming & Conventions
	•	Entities: one Lua entry file per domain (e.g., entities/corn/corn.lua) exposes factory functions (prefabs) and domain helpers.
Example exports:
	•	CornPlant.spawn(cellX, cellY) → entity id
	•	CornPlant.advanceStage(e)
	•	CornFruit.spawnAtSocket(parentE, socketName)
	•	Models: for crops, each growth stage is a separate file; the final stage includes named nodes like Socket_CornA, Socket_CornB, etc. Fruit is a separate model.
	•	Materials: keep tiny Lua material descriptor files (e.g., *.mat.lua) that your loader applies to models or passes—keeps look tweaks centralized.
	•	Textures: per-entity textures live under that entity; shared UI textures remain global.
	•	SFX: entity-specific SFX under the entity; UI/music/ambient sounds globally under /assets.

Key Implementations

1) ECS Core ( /core/ecs.lua )
	•	Entities: sequential IDs; reuse holes after deletion.
	•	Components: module-scoped registries keyed by component name; each stores entityId → data.
	•	Queries: ecs:each({ "transform", "renderable" }, fn); index once on registration for speed.
	•	Systems: registered lists: updateSystems, drawSystems. Provide ecs:addSystem(systemTbl).

2) Grid + Placement
	•	GridSystem builds a world-space grid, stores occupancy, and computes a hovered cell from mouse ray vs plane.
	•	PlacementSystem: placement rules (inside farm bounds, not overlapping occupied, correct surface), ghost preview mesh/material and colored outline states.

3) Tools-as-Cursor
	•	entities/tools/ create tool prefabs with component tags, and ToolSystem interprets input:
	•	Shovel: toggles soil tile between regular ↔ tilled; plays shovel_dig.wav.
	•	Watering can: cursor model tilts toward target; spawns water particles (/fx/water_spray.lua); increases soil.wetness, kicks off soil darken timer.
	•	Seed tool: consumes seed:<crop> stack; plants entity domain prefab (e.g., CornPlant.spawn).
	•	Harvest tool: detects that a crop is at final stage; detaches fruit entities from sockets, moves items into inventory, triggers sparkle FX + SFX.

4) Crops with Sockets
	•	crop_growth_system.lua:
	•	progress += growthSpeed * hydrationFactor * fertilizerFactor * dt
	•	Stage thresholds switch model (renderable.model = '.../stage_3.fbx').
	•	On final stage, scan stage_4 model nodes for socket names listed in entities/corn/sockets.lua. For each socket, spawn a CornFruit and attach via the sockets component (map socketName → fruitEntityId).
	•	Drawing phase: update fruit transform by sampling socket node’s pose from the parent model each frame (or cache local offsets and combine with parent transform).

5) Soil Darkening
	•	soil.lua has wetness and darkenTimer. HydrationSystem decays wetness over time; RenderSystem lerps soil material albedo toward a darker color when darkenTimer > 0.

6) Inventory & Economy
	•	inventory_system.lua: stackable items { id = "seed:corn", qty = 10 }, tools as non-stackables.
	•	economy_system.lua: use /gameplay/shop_db.lua and /gameplay/balance.lua for prices/payouts. Starter money and items defined in /gameplay/starter_pack.lua.

7) Scenes
	•	/scene/manager.lua exposes Scene.push(name), Scene.swap(name), Scene.pop(), and transition helpers (fade overlay).
	•	/scene/farm.lua: grid, tools, crops, fences, compost bin.
	•	/scene/town.lua: shops, ambient props/NPCs (non-interactive), sell stand.

8) UI
	•	/ui/theme.lua: pastel palette, rounded corners, shadow/blur hints, font declarations, UI SFX map.
	•	/ui/hud.lua: hotbar (1=Shovel, 2=Watering, 3=Seed, 4=Harvest), money, travel button, grid tooltip.
	•	/ui/inventory.lua + /ui/shop.lua: drag-drop optional, or simple click buy/sell.
	•	/ui/menus.lua: main/pause/settings.

9) Audio
	•	/systems/audio_system.lua manages looping cozy piano and ambient farm sounds; plays one-shots for tools and UI.

10) Save/Load
	•	/io/save.lua serializes:
	•	Entities and their components (only the needed fields)
	•	Inventory, wallet, farm bounds/fences, compost states, time progression
	•	Version field for future migrations.

⸻

Deliverables
	1.	Working project runnable by dragging the folder onto the LÖVR executable (desktop).
	2.	Custom ECS with docs in comments.
	3.	DDD entity domains (corn complete, soil, tools, fence, compost bin, shops, town props).
	4.	Grid building + tools-as-cursor with particles/SFX and soil darkening.
	5.	Corn: 4 growth stages + dynamic socketed fruit; harvest and sell loop working.
	6.	UI + Audio wired (HUD, inventory, shop, pause).
	7.	Save/Load JSON with a minimal schema and versioning.
	8.	README explaining run, controls, how to add a new crop domain.

⸻

Controls (default)
	•	Camera: RMB drag = orbit, MMB/Alt+LMB = pan, wheel = zoom
	•	Tools: 1 Shovel, 2 Watering, 3 Seed (corn), 4 Harvest
	•	Menus: I Inventory, Esc Pause, T Travel Farm↔Town

⸻

Quick “Corn” Domain Notes (example)
	•	entities/corn/config.lua:
```lua
return {
  id = 'corn',
  sellPrice = 6,
  stages = {
    { model = 'entities/corn/models/stage_1.fbx', time = 20 },
    { model = 'entities/corn/models/stage_2.fbx', time = 30 },
    { model = 'entities/corn/models/stage_3.fbx', time = 40 },
    { model = 'entities/corn/models/stage_4.fbx', time = 50, sockets = { 'Socket_CornA', 'Socket_CornB' } }
  },
  fruit = {
    model = 'entities/corn/models/fruit_cob.fbx',
    itemId = 'crop:corn'
  }
}
```
	•	entities/corn/sockets.lua keeps any naming rules or per-socket offsets if needed.