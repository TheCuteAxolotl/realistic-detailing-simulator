# Realistic Detailing Simulator

A Roblox detailing simulator focused on realistic process, technique, and vehicle condition rather than one-click cleaning.

## First playable prototype

The current vertical slice creates a practice detailing bay and a multi-panel practice car automatically when the server starts.

Players can:

- Pressure wash individual body panels
- Apply foam
- Contact wash with a mitt
- Rinse
- Dry the vehicle
- Miss individual spots instead of cleaning the entire car at once
- Build a job score from the actual condition of every panel
- Earn cash after properly completing the vehicle
- Save cash between sessions with Roblox DataStoreService

## Controls

- `1` — Pressure Washer
- `2` — Foam Cannon
- `3` — Wash Mitt
- `4` — Drying Towel
- Click/tap a body panel to use the selected tool

The HUD also has tool buttons, so the prototype is usable without number keys.

## Roblox Studio + Rojo

1. Install Roblox Studio.
2. Install Rojo 7.x and the Rojo Studio plugin.
3. Clone this repository.
4. From the repository folder, run:

```bash
rojo serve
```

5. Open a blank Baseplate place in Roblox Studio.
6. Open the Rojo plugin and connect to the running server.
7. Sync the project.
8. Press Play.

The prototype generates its own practice car and bay at runtime, so no model import is required for the first test.

## DataStore testing in Studio

Cash persistence uses `DataStoreService`. To test saves in Studio, publish the experience and enable **Game Settings → Security → Enable Studio Access to API Services** for a test place. The game still runs if DataStore access is unavailable; it simply uses session-only cash.

## Project layout

```text
src/
  client/
    DetailingController.client.luau
  server/
    Bootstrap.server.luau
    PlayerDataService.luau
    VehicleService.luau
  shared/
    Config.luau
    ToolData.luau
```

## Design direction

Planned systems include wheels, bugs, road film, iron contamination, clay, interiors, carpet extraction, polishing, paint defects, ceramic coatings, customer requests, reputation, realistic chemicals/equipment, mobile detailing rigs, garages, employees, weather, and multiplayer jobs.
