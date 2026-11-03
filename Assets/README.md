# Application icon

`AppIcon.png` is the 1024 × 1024 transparent source for the app icon. The build script generates the standard macOS iconset sizes (16, 32, 128, 256, 512 points at 1× and 2×) and packages `AppIcon.icns` in the app bundle. The menu bar continues to use the existing monochrome system symbol.

Created with the built-in imagegen tool, then resized using macOS `sips`. The artwork is covered by this repository's MIT license.

Design prompt:

> A production macOS application icon for FinderSideButtons. A centered, front-facing blue rounded-square tile on a transparent square canvas, with a large white satin ceramic mouse, two distinct buttons on its left edge, and bold white back/forward chevrons below. Azure-to-cobalt gradient, restrained relief and soft interior shadows. Broad clean shapes readable at small sizes. No text, letters, numbers, Apple logo, Finder face, or mockup scene.

Final refinement prompt:

> Refine this exact app icon for production macOS use. Preserve the blue rounded-square tile, large white sculpted mouse with two left side buttons, the two white navigation chevrons, their layout, colors and native 3D satin material. Change only the outer boundary treatment: remove ALL cyan halo, outer glow, ragged fringe and colored noise around the tile. Make the rounded-square silhouette beautifully crisp and smoothly antialiased. Add generous even fully transparent padding so the entire tile occupies 82% of the square image width and height, centered. Outside the tile must be fully transparent, no glow, no shadow outside tile, no checkerboard drawn. Interior shadows and relief remain. One square production icon, no text, no mockup.
