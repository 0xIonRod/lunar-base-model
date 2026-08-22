from pathlib import Path

import numpy as np
from PIL import Image, TiffImagePlugin


ROOT = Path(r"C:\Users\salek\OneDrive\Desktop\NASA-lunar-base-model\luna2_direct_sim")
SOURCE = ROOT / "raw" / "LDEM_4.JP2"
OUT = ROOT / "site" / "luna2" / "materials" / "textures" / "heightmap.tif"

# LDEM_4 is a global 4-pixel/degree cylindrical DEM. The JP2 stores signed
# elevations with a 32768 digital-number offset. Crop a fresh 32x32 sample
# around the Luna 2 / Sinus Lunicus region for the native SpawnDemTerrain API.
center_lat = 32.4
center_lon = -1.9
pixels_per_degree = 4.0
width = height = 32

image = Image.open(SOURCE)
samples = np.asarray(image, dtype=np.int32) - 32768
cx = int(round((center_lon + 180.0) * pixels_per_degree))
cy = int(round((90.0 - center_lat) * pixels_per_degree))
x0 = cx - width // 2
y0 = cy - height // 2
crop = samples[y0 : y0 + height, x0 : x0 + width].astype(np.int32)
if crop.shape != (height, width):
    raise RuntimeError(f"unexpected crop shape: {crop.shape}")

lon_min = -180.0 + x0 / pixels_per_degree
lat_max = 90.0 - y0 / pixels_per_degree

OUT.parent.mkdir(parents=True, exist_ok=True)
tiffinfo = TiffImagePlugin.ImageFileDirectory_v2()
tiffinfo[33550] = (1.0 / pixels_per_degree, 1.0 / pixels_per_degree, 0.0)
tiffinfo[33922] = (0.0, 0.0, 0.0, lon_min, lat_max, 0.0)
# GeoTIFF keys: geographic model, pixel-is-area raster, WGS84 geographic CRS,
# and degree angular units. LunCoSim consumes the georeference to place the
# direct SpawnDemTerrain crop; no surfacegenerator metadata is involved.
tiffinfo[34735] = (
    1, 1, 0, 4,
    1024, 0, 1, 2,
    1025, 0, 1, 1,
    2048, 0, 1, 4326,
    2054, 0, 1, 9102,
)

Image.fromarray(crop, mode="I").save(OUT, format="TIFF", tiffinfo=tiffinfo)
print(f"wrote {OUT}")
print(f"crop origin lon={lon_min:.3f}, lat={lat_max:.3f}; center={center_lat},{center_lon}")
print(f"shape={crop.shape}; elevation_m={int(crop.min())}..{int(crop.max())}; mean={float(crop.mean()):.1f}")
