#!/usr/bin/env python3
"""
Creates the app icon by replacing the black background of the logo with #D4FF00 (primary green).
Output: 1024x1024 PNG suitable for flutter_launcher_icons.
"""
from pathlib import Path

from PIL import Image

# Background color: #D4FF00 (primary green / accent lime)
BG_R, BG_G, BG_B = 0xD4, 0xFF, 0x00

# Black/dark threshold - pixels darker than this become background
# Brown "OY!" text is ~#50301B (RGB 80,48,27), so threshold must be < 27
BLACK_THRESHOLD = 25  # Only replace pure black / near-black background


def main():
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent
    logo_path = project_root / "open_yapper_site" / "public" / "logo front.png"
    out_path = project_root / "assets" / "app_icon.png"

    if not logo_path.exists():
        raise FileNotFoundError(f"Logo not found: {logo_path}")

    assets_dir = project_root / "assets"
    assets_dir.mkdir(exist_ok=True)

    img = Image.open(logo_path).convert("RGBA")
    pixels = img.load()
    w, h = img.size

    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            # Replace black/near-black pixels with background color
            if r <= BLACK_THRESHOLD and g <= BLACK_THRESHOLD and b <= BLACK_THRESHOLD:
                pixels[x, y] = (BG_R, BG_G, BG_B, 255)
            # Optional: make fully transparent pixels use background
            elif a < 128:
                pixels[x, y] = (BG_R, BG_G, BG_B, 255)

    # Resize to 1024x1024 for flutter_launcher_icons (recommended size)
    img_resized = img.resize((1024, 1024), Image.Resampling.LANCZOS)

    # Flatten onto a solid background so output has no transparency.
    solid_bg = Image.new("RGB", (1024, 1024), (BG_R, BG_G, BG_B))
    solid_bg.paste(img_resized, (0, 0), img_resized)
    solid_bg.save(out_path, "PNG")
    print(f"Created app icon: {out_path}")
    return str(out_path)


if __name__ == "__main__":
    main()
