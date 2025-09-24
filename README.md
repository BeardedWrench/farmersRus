# Cozy Farmer

Cozy Farmer is a desktop-only, low-poly farming builder created with [LÖVR](https://lovr.org). The project ships with a custom Entity Component System (ECS) and a Domain-Driven Design (DDD) layout where every domain (soil, crops, tools, shops, props...) owns its own code and assets under `entities/<domain>/`.

Drag the folder onto the LÖVR executable or run `lovr .` from the project root to play. The save file (`save.json`) is written next to the project and stores the world state, player inventory, wallet, and crop progress.

## Controls

- **Camera**: Right mouse drag to orbit, middle mouse to pan, scroll wheel to zoom.
- **Tools**: `1` Shovel, `2` Watering Can, `3` Seed Tool (defaults to corn), `4` Harvest Sickle. Left click applies the active tool.
- **Menus**: `I` toggles the inventory overlay, `T` travels between Farm and Town, `Esc` placeholder for pause.

## Architecture Overview

- `core/` implements the lightweight ECS (`core/ecs.lua`), event bus, resource manager, and input/time helpers.
- `systems/` houses cross-domain systems (camera, grid/placement, tools, growth, economy, audio, UI, rendering, save/load, etc.). Each system registers queries against the ECS and runs during the update/draw passes.
- `components/` defines reusable component factories (`transform`, `renderable`, `soil`, `crop`, `inventory`, `wallet`, ...).
- `entities/<domain>/` contains domain-specific prefabs and assets. Example: `entities/corn/` contains corn configs, sockets, and prefab constructors for plants and fruit.
- `scene/` manages the Farm/Town scenes, transitions, and setup logic. The scene manager owns fade transitions and exposes `scene:travel` events.
- `ui/` collects theme and stub widget modules used by the UI system overlay.
- `gameplay/` contains balancing databases: crop registry, shop stock, pricing, and starter inventory.
- `fx/` defines simple particle descriptors consumed by the FX system.
- `io/save.lua` provides JSON encode/decode helpers for deterministic save files.

## Feature Highlights

- **Orbit/Pan/Zoom Camera** with smooth deltas and adjustable distance limits.
- **Grid Building & Placement**: Hover highlights display valid cells (green), blocked (red), occupied (yellow), and preview states.
- **Tools-as-Cursor** behaviour swaps ghost previews and triggers contextual gameplay: tilling soil, watering (boosts hydration and FX), planting seeds, and harvesting ripe crops.
- **Crop Growth & Sockets**: Crops advance through configured growth stages. Final-stage crops spawn fruit entities at named sockets and mark themselves as harvest-ready.
- **Soil & Hydration Simulation**: Soil wetness decays over time, tinting tiles. Hydration feeds into crop growth speed, and FX/audio respond to tool usage.
- **Inventory & Economy**: Starter tools and seeds are provisioned; buying/selling hooks emit audio feedback and update the wallet.
- **Scenes & Travel**: Farm and Town scenes populate different entity sets. A fade transition mediates travel.
- **Save/Load**: On quit, the ECS serialises soil, crops, and player state to `save.json`. Existing saves are loaded on boot.

## Adding a New Crop Domain

1. Duplicate `entities/corn/` into `entities/<crop>/` and replace models/materials/textures with your assets.
2. Update `<crop>/config.lua` with stage model paths, stage durations, socket names, and fruit metadata (`itemId`, `count`).
3. Configure socket offsets in `<crop>/sockets.lua` so fruit attaches correctly in the world.
4. Adjust `<crop>/<crop>.lua` to spawn the plant and fruit using your geometry. Ensure it exposes `spawn`, `spawnFruit`, and `applyStage` similar to the corn implementation.
5. Register the crop in `gameplay/crops_db.lua` using the new domain module. Provide `spawn`, `spawnFruit`, and `applyStage` adapters so systems can use the crop.
6. Optionally add a starter pack entry (`gameplay/starter_pack.lua`) and shop pricing (`gameplay/shop_db.lua`, `gameplay/balance.lua`) for seeds and sell values.

## Repository Layout (partial)

```
core/            # ECS infrastructure, resource loading, input, events
systems/         # Camera, grid, placement, tools, crop growth, UI, audio, FX, render, save, etc.
components/      # Reusable component factories (transform, renderable, crop, soil...)
entities/        # Domain folders (corn, soil, tools, fence, compost_bin, shops, props_town, ...)
scene/           # Scene manager, farm, and town scenes
ui/              # UI theme and widget stubs consumed by the UI overlay system
gameplay/        # Tuning databases: crops, shops, balance, starter pack
fx/              # Particle descriptors
io/              # Save/load utilities
```

## Development Notes

- The ECS supports fast signature-based queries and emits lifecycle events (`ecs:entityCreated`, `ecs:componentAdded`, etc.) for debugging or editor tooling.
- The resource manager gracefully falls back to procedural placeholders if a model/texture/sound asset is missing, keeping the project runnable without binary assets.
- Systems communicate via the event bus (e.g., `harvest:collect`, `fx:water`, `economy:buy`). Events are queued and flushed once per frame.
- The project avoids external dependencies beyond LÖVR, keeping deployment portable.
