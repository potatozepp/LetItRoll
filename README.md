# Let It Roll

A Godot 4.x mobile MVP for a relaxing scale-growth game about rolling an extremely tiny sticky ball into larger materials until it becomes enormous.

## MVP Scope

Phase 1 is playable and intentionally simple:

- Portrait mobile project configuration with lightweight 2D rendering.
- Smooth drag/swipe controls for touch plus WASD keyboard controls for desktop testing.
- Modular player, run state, growth mode, camera, HUD, and procedural spawning scripts.
- Absorbable objects spawn endlessly around the player based on the current size tier.
- The camera smoothly zooms out as the ball grows to sell the sense of scale.

## Project Structure

```text
scenes/                 Godot scenes for the main game and spawned entities
scripts/core/           Shared run configuration and runtime state
scripts/player/         Player movement and scale-aware camera behavior
scripts/world/          Procedural spawning and absorbable world objects
scripts/modes/          Growth rule resources for future game modes
scripts/ui/             Gameplay HUD
scripts/save/           Save-data foundation for upgrades and progression
```

## Roadmap

1. **Phase 1:** Player movement, camera, growth, procedural spawning, collision, size scaling.
2. **Phase 2:** Hazards, upgrades, save system integration, menus, pause flow.
3. **Phase 3:** Achievements, multiple growth modes, improved visuals, polish and balancing.

Keep each phase playable before expanding systems.

## Terrain-First World Design

The ground is the primary resource. Terrain is generated in chunks of absorbable cells, and the player consumes cells underneath the ball when their current mass is high enough. Consumed cells stop drawing, leaving visible holes behind; spawned objects remain as secondary bonus resources layered above the destructible terrain.
