"""Build the bundled OFL font subset from an upstream Noto Serif SC variable TTF.
Usage: python3 scripts/crailglitun_subset_font.py /path/to/NotoSerifSC.ttf
Requires fonttools for this build utility only; the app has no font dependency.
Upstream: https://github.com/google/fonts/tree/main/ofl/notoserifsc
"""
from pathlib import Path
import sys
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools import subset

root = Path(__file__).resolve().parents[1]
font = instantiateVariableFont(TTFont(sys.argv[1]), {'wght': 650}, inplace=True)
text = ''.join(p.read_text() for p in (root / 'Crailglitun').rglob('*.swift'))
text += (root / 'Crailglitun/Resources/tasks.json').read_text()
options = subset.Options()
options.name_IDs = ['*']
options.name_legacy = True
options.name_languages = ['*']
subsetter = subset.Subsetter(options=options)
subsetter.populate(text=text)
subsetter.subset(font)
for name in font['name'].names:
    if name.nameID in [1, 4, 6, 16]:
        name.string = ('TurnSceneSerif' if name.nameID == 6 else 'TurnScene Serif').encode(name.getEncoding())
path = root / 'Crailglitun/Resources/TurnSceneSerif.ttf'
font.save(path)
print(f'Saved {path.name}: {path.stat().st_size} bytes')
