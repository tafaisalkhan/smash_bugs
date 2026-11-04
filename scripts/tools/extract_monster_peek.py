from PIL import Image

sheet = Image.open('assets/sprites/beetle_sheet.png').convert('RGBA')
fw = 1200 // 4  # 300
fh = 896 // 3   # 298

# Crop beetle peek face: row 0 col 0 (or row 1 col 0)
peek = sheet.crop((0, 0, fw, fh))
# Trim transparency
bbox = peek.getbbox()
if bbox:
    peek = peek.crop(bbox)

# Scale nicely to ~130px wide
w = 140
h = int(w * peek.height / peek.width)
peek = peek.resize((w, h), Image.Resampling.LANCZOS)
peek.save('assets/smash/monster_peek.png')
print('Monster peek sprite extracted!')
