import os, base64
from io import BytesIO
from PIL import Image

src_path = r"C:\Users\Supreme Traders\.gemini\antigravity-cli\brain\c56e7ac1-ee83-40f2-818a-1404ec5ab09c\app_icon_single_bug_1793729934063.jpg"
project_dir = r"C:\Users\Supreme Traders\Documents\interview\smash_bugs_flys"

master_img = Image.open(src_path).convert("RGBA")
print(f"Master image loaded: {master_img.size}")

# 1. Save 1024x1024 master
os.makedirs(os.path.join(project_dir, "assets", "generated"), exist_ok=True)
master_target = os.path.join(project_dir, "assets", "generated", "app_icon_single_bug.png")
master_img.save(master_target, format="PNG")
print(f"Saved: {master_target}")

# 2. Generate 512x512 high quality PNG
img_512 = master_img.resize((512, 512), Image.Resampling.LANCZOS)

png_512_targets = [
    os.path.join(project_dir, "assets", "generated", "app-icon.png"),
    os.path.join(project_dir, "assets", "generated", "app-icon-safe.png"),
    os.path.join(project_dir, "assets", "generated", "mascot-logo.png"),
    os.path.join(project_dir, "assets", "smash", "splash_mascot.png"),
    os.path.join(project_dir, "assets", "smash", "app_icon_art.png"),
    os.path.join(project_dir, "android", "build", "src", "main", "assets", "assets", "generated", "app-icon-safe.png"),
]

for t in png_512_targets:
    os.makedirs(os.path.dirname(t), exist_ok=True)
    img_512.save(t, format="PNG")
    print(f"Saved 512x512 PNG: {t}")

# 3. Generate SVG files with base64 embedded high quality PNG
buf = BytesIO()
img_512.save(buf, format="PNG")
b64_str = base64.b64encode(buf.getvalue()).decode("utf-8")

svg_content = f'''<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">
  <defs>
    <clipPath id="rounded">
      <rect x="0" y="0" width="512" height="512" rx="110" />
    </clipPath>
  </defs>
  <image width="512" height="512" href="data:image/png;base64,{b64_str}" clip-path="url(#rounded)" />
</svg>'''

svg_targets = [
    os.path.join(project_dir, "icon.svg"),
    os.path.join(project_dir, "assets", "smash", "app_icon.svg"),
    os.path.join(project_dir, "assets", "generated", "mathmind-splash.svg"),
    os.path.join(project_dir, "android", "build", "src", "main", "assets", "icon.svg"),
]

for t in svg_targets:
    os.makedirs(os.path.dirname(t), exist_ok=True)
    with open(t, "w", encoding="utf-8") as f:
        f.write(svg_content)
    print(f"Saved SVG: {t}")

# 4. Generate Android splash_icon.webp (1254x1254)
splash_img = master_img.resize((1254, 1254), Image.Resampling.LANCZOS)
splash_targets = [
    os.path.join(project_dir, "android", "build", "res", "drawable", "splash_icon.webp"),
    os.path.join(project_dir, "android", "build", "build", "intermediates", "packaged_res", "standardDebug", "packageStandardDebugResources", "drawable", "splash_icon.webp"),
]
for t in splash_targets:
    if os.path.exists(os.path.dirname(t)):
        splash_img.save(t, format="WEBP", quality=95)
        print(f"Saved splash WEBP: {t}")

# 5. Generate Android mipmap icons at standard densities
mipmap_sizes = {
    "mipmap": 48,
    "mipmap-mdpi-v4": 48,
    "mipmap-hdpi-v4": 72,
    "mipmap-xhdpi-v4": 96,
    "mipmap-xxhdpi-v4": 144,
    "mipmap-xxxhdpi-v4": 192,
}

for folder, size in mipmap_sizes.items():
    icon_resized = master_img.resize((size, size), Image.Resampling.LANCZOS)
    res_dirs = [
        os.path.join(project_dir, "android", "build", "res", folder),
        os.path.join(project_dir, "android", "build", "build", "intermediates", "packaged_res", "standardDebug", "packageStandardDebugResources", folder)
    ]
    for d in res_dirs:
        if os.path.exists(d):
            out_file = os.path.join(d, "icon.webp")
            icon_resized.save(out_file, format="WEBP", quality=95)
            print(f"Saved {size}x{size} WEBP: {out_file}")

# 6. Check intermediates in mergeStandardDebugAssets
merged_assets_dir = os.path.join(project_dir, "android", "build", "build", "intermediates", "assets", "standardDebug", "mergeStandardDebugAssets")
if os.path.exists(merged_assets_dir):
    merged_icon = os.path.join(merged_assets_dir, "icon.svg")
    if os.path.exists(merged_icon):
        with open(merged_icon, "w", encoding="utf-8") as f:
            f.write(svg_content)
        print(f"Updated: {merged_icon}")
    merged_safe = os.path.join(merged_assets_dir, "assets", "generated", "app-icon-safe.png")
    if os.path.exists(merged_safe):
        img_512.save(merged_safe, format="PNG")
        print(f"Updated: {merged_safe}")

print("\nALL ICONS AND SPLASH ART SUCCESSFULLY REPLACED WITH SINGLE BUG ARTWORK!")
