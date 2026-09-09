# Let It Roll

A Godot 4 portrait MVP about **physically building a rolling ball from terrain**. The ball does not gain hidden mass by touching the ground: it lifts finite material from hex terrain tiles, carries visible chunks on its surface, compacts that material while rolling, and grows from the material that remains attached.

## Core MVP loop

1. Start tiny in a concrete-dominated test island.
2. Find the small grass and dirt hexes that are collectable at starter size.
3. Roll over a patch to transfer its finite volume onto directional sectors of the ball.
4. Keep moving to compress fresh material (grass becomes dirt); fresh surface capacity is limited.
5. Balance movement directions to keep the ball round. Repeated straight rolling produces a visibly lopsided, unstable wheel shape.
6. Water strips loose material. Larger physical size unlocks the data-driven gravel, stone, asphalt, concrete, and rock tiers.

## Controls

- **Desktop:** WASD to roll, Shift to boost, Escape to pause.
- **Mobile:** drag the on-screen joystick and hold **BOOST**.

## Architecture

- `MaterialCatalog.gd` defines material hardness, minimum size, collection rate, density, and visual palette.
- `TerrainChunk.gd` generates efficient, finite-volume hex tiles; `TerrainManager.gd` only returns collected material records and never awards hidden growth.
- `PlayerBall.gd` owns material sectors, surface capacity, compaction, water wash-off, visual deformation, and instability failure.
- `RunState.gd` receives a size derived from attached physical volume; legacy object-growth support remains isolated for future bonus entities.

## Testing the prototype

Start a run at the center of the small test island. Roll into a brown/green hex, then away: colored attached chunks remain on the ball and the tile darkens as volume is removed. Continue in one direction to see an uneven shell and warning, or change directions to spread the coating. Roll into blue water farther out to wash loose chunks off. Concrete is intentionally not collectable at starter size.
