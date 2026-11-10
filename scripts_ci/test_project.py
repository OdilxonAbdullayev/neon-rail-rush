"""Small structural checks; not a substitute for Godot compilation/Android QA."""
from pathlib import Path
import re, wave

ROOT=Path(__file__).resolve().parents[1]
REQUIRED=[
    'project.godot','export_presets.cfg','scenes/main.tscn','scripts/runner.gd',
    '.github/workflows/android-apk.yml','assets/icon.png','audio/neon_loop.wav',
    'audio/start.wav','audio/coin.wav','audio/jump.wav','audio/slide.wav',
    'audio/hit.wav','audio/power.wav',
]
for name in REQUIRED:
    p=ROOT/name
    assert p.is_file() and p.stat().st_size>0, f'Missing or empty: {name}'
source=(ROOT/'scripts/runner.gd').read_text(encoding='utf-8')
for needle in ['func _ready()', 'func _spawn_wave()', 'func _change_lane(',
               'func _jump()', 'func _slide()', 'func _end_game()',
               'func _load_save()', 'func _save_progress()', 'func _handle_swipe(',
               '"train"', '"barrier"', '"gate"', '"coin"', '"magnet"', '"shield"',
               'NOTIFICATION_APPLICATION_PAUSED', 'MAX_SPEED']:
    assert needle in source, f'Missing expected code feature: {needle}'
for name in ['coin','jump','slide','power','start','hit','neon_loop']:
    with wave.open(str(ROOT/'audio'/f'{name}.wav')) as wav:
        assert wav.getnframes()>500
        assert wav.getnchannels()==1
        assert wav.getframerate()==22050
assert 'name="Android"' in (ROOT/'export_presets.cfg').read_text()
assert 'barichello/godot-ci:4.4.1' in (ROOT/'.github/workflows/android-apk.yml').read_text()
assert 'res://scripts/runner.gd' in (ROOT/'scenes/main.tscn').read_text()
assert (ROOT/'assets/icon.png').read_bytes()[:8]==b'\x89PNG\r\n\x1a\n'
print(f'Passed structural tests: {len(REQUIRED)} files, 7 WAVs, core gameplay and workflow present')
