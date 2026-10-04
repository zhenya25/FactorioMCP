# City Block 96x96 - design rules

Root book label: `SpaceAge City Block 96x96`.

1. **Grid.** Square blocks 96x96 on an absolute grid. Intersections sit at multiples of 96, so rails run on chunk borders and a block is 3x3 chunks.
2. **Rails.** Double track, right-hand traffic, tracks 3 tiles either side of the block border. Trains: 1 locomotive + 4 wagons.
3. **Snapping.** Every blueprint snaps to the absolute 96x96 grid, so it cannot be misplaced far from the base.
4. **Power trunk.** Big poles in the rail median, part of the intersection blueprint; every block borders it on all four sides.
5. **Block frame.** Every block reserves four slots at its quarter points: roboport at 24/72 tiles from the rail centre lines, big pole on its corner-side diagonal at 21/75 (`04-grid/block-frame`). One drone network across all blocks, every tile covered. Fillings must leave these slots free.
6. **Fillings.** One block = one product, shipped by train. Modest throughput; the user scales by stamping another block. Usable interior is about 86x86, corners are cut about 13 tiles by rail turns.
7. **Exempt:** books 1-3 (before rails) follow none of the grid rules.
8. **Planets.** City blocks apply to Nauvis (and possibly Vulcanus). Fulgora, Gleba and Aquilo get their own layouts.
