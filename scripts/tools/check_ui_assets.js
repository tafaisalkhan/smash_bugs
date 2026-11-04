const fs = require('fs');
const path = require('path');

let errors = 0;
for (const directory of ['scenes/ui_screens', 'scenes/ui_items', 'scenes']) {
  for (const file of fs.readdirSync(directory).filter(name => name.endsWith('.tscn') && (directory !== 'scenes' || ['settings.tscn', 'level_select.tscn'].includes(name)))) {
    const scene = path.join(directory, file);
    const source = fs.readFileSync(scene, 'utf8');
    const steps = Number(source.match(/load_steps=(\d+)/)?.[1]);
    const resources = 1
      + (source.match(/^\[ext_resource /gm) || []).length
      + (source.match(/^\[sub_resource /gm) || []).length;
    if (steps !== resources) {
      console.error(`${scene}: load_steps ${steps}, expected ${resources}`);
      errors++;
    }
    for (const match of source.matchAll(/path="res:\/\/([^"]+)"/g)) {
      if (!fs.existsSync(match[1])) {
        console.error(`${scene}: missing ${match[1]}`);
        errors++;
      }
    }
  }
}
for (const script of [
  'scripts/main.gd',
  'scripts/ui_screens/textured_home_screen.gd',
  'scripts/ui_screens/textured_market_screen.gd',
  'scripts/ui_screens/textured_info_screen.gd',
  'scripts/ui_screens/textured_reward_screen.gd',
  'scripts/textured_advanced_settings.gd',
  'scripts/textured_level_select.gd'
]) {
  const source = fs.readFileSync(script, 'utf8');
  for (const match of source.matchAll(/preload\("res:\/\/([^\"]+)"\)/g)) {
    if (!fs.existsSync(match[1])) {
      console.error(`${script}: missing ${match[1]}`);
      errors++;
    }
  }
}
for (const file of fs.readdirSync('assets/generated/ui').filter(name => name.endsWith('-screen.png') || name.endsWith('-stars.png'))) {
  const asset = path.join('assets/generated/ui', file);
  const image = fs.readFileSync(asset);
  if (image.subarray(0, 8).toString('hex') !== '89504e470d0a1a0a' || image.readUInt32BE(16) < 500 || image.readUInt32BE(20) < 900) {
    console.error(`${asset}: invalid or undersized PNG`);
    errors++;
  }
}
console.log(errors ? `${errors} UI asset errors` : 'UI asset references OK');
process.exitCode = errors ? 1 : 0;
