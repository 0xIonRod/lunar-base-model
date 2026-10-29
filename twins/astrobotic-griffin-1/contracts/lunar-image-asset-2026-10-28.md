# Optional NASA Moon appearance asset

`lroc_moon_2025_8k` declares the NASA SVS 2025 LROC/LOLA color map and the native texture processing pipeline in `Assets.toml`. The source is about 232 MiB, 8192 × 4096, 16-bit sRGB. Raw source and processed PNG belong in `.cache`; the source SHA-256 is pinned. Credit: NASA’s Scientific Visualization Studio.

Source: https://svs.gsfc.nasa.gov/4720/

Request the asset through Twin assets or the native dataset command. Its processed logical address is `twin://astrobotic-griffin-1/textures/moon/lroc_color_2025_8k.png`. An opting-in scene can set `lunco:body:albedoMap` on its Moon body prim to this address. The default mission is unchanged.

This is global visualization imagery. Polar data include lower-resolution LOLA albedo. Nobile DEM/orthophoto sources remain authoritative for local terrain; the global image must not be presented as metre-scale site imagery.
