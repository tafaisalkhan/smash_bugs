import math
from PIL import Image, ImageDraw

W, H = 440, 560
img = Image.new('RGBA', (W, H), (0, 0, 0, 0))

# 1. Shadow underneath the sheet
shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
s_draw = ImageDraw.Draw(shadow)
# Subtle soft shadow
for offset in range(16, 0, -2):
    alpha = int(45 * (1.0 - offset / 16.0))
    s_draw.rounded_rectangle([20 + offset//2, 40 + offset, W - 20 + offset//2, H - 30 + offset], 18, fill=(0, 0, 0, alpha))
img = Image.alpha_composite(img, shadow)

# 2. Main Paper Sheet
paper = Image.new('RGBA', (W, H), (0, 0, 0, 0))
p_draw = ImageDraw.Draw(paper)

# Soft paper cream background
paper_rect = [20, 35, W - 20, H - 35]
p_draw.rounded_rectangle(paper_rect, 14, fill=(255, 252, 243, 255), outline=(232, 224, 206, 255), width=2)

# Page curl effect at bottom-right
# Cutout the bottom-right corner and replace with folded curl
curl_w, curl_h = 75, 75
cx = W - 20
cy = H - 35
# Curl shadow
p_draw.polygon([(cx - curl_w - 6, cy), (cx, cy - curl_h - 6), (cx, cy)], fill=(210, 200, 180, 255))
# Curl fold (warmer reverse side of paper)
p_draw.polygon([(cx - curl_w, cy), (cx, cy - curl_h), (cx - curl_w * 0.45, cy - curl_h * 0.45)], fill=(240, 230, 205, 255), outline=(218, 205, 180, 255))

img = Image.alpha_composite(img, paper)

# 3. Two Red Push Pins at Top Corners
pin_l = (48, 42)
pin_r = (W - 48, 42)

for px, py in [pin_l, pin_r]:
    pin = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    pd = ImageDraw.Draw(pin)
    # Pin drop shadow
    pd.ellipse([px - 4, py + 8, px + 18, py + 22], fill=(0, 0, 0, 60))
    # Pin base ring
    pd.ellipse([px - 14, py - 6, px + 14, py + 16], fill=(185, 30, 35, 255), outline=(130, 15, 20, 255), width=2)
    # Pin neck
    pd.rectangle([px - 6, py - 14, px + 6, py - 4], fill=(220, 50, 55, 255))
    # Pin top bulb
    pd.ellipse([px - 12, py - 24, px + 12, py - 4], fill=(245, 65, 75, 255), outline=(150, 20, 25, 255), width=2)
    # Gloss highlight
    pd.ellipse([px - 7, py - 20, px - 1, py - 12], fill=(255, 180, 185, 220))
    img = Image.alpha_composite(img, pin)

img.save('assets/smash/notice_paper.png')
print('Notice paper successfully created!')
