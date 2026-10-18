"""Assemble dist/: omit3_task.bundle.js (design + icon sizes + task), chs_protocol.js, index.html."""
import json, os, sys, glob
from PIL import Image
sys.path.insert(0, os.path.dirname(__file__))
from design import DESIGN

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BASE_URL = sys.argv[1] if len(sys.argv) > 1 else 'https://raw.githubusercontent.com/ashleyjthomas/OMIT3-CHS/main/'

json.dump(DESIGN, open(os.path.join(ROOT, 'design.json'), 'w'), indent=1)
icons = {os.path.basename(f)[:-4]: list(Image.open(f).size) for f in sorted(glob.glob(os.path.join(ROOT, 'assets/icons/*.png')))}

task = open(os.path.join(ROOT, 'src/omit3_task.js')).read()
bundle = ('window.OMIT3_DESIGN = ' + json.dumps(DESIGN) + ';\n' +
          'window.OMIT3_ICON_SIZES = ' + json.dumps(icons) + ';\n' + task)
os.makedirs(os.path.join(ROOT, 'dist'), exist_ok=True)
open(os.path.join(ROOT, 'dist/omit3_task.bundle.js'), 'w').write(bundle)

tmpl = open(os.path.join(ROOT, 'src/chs_protocol_template.js')).read()
open(os.path.join(ROOT, 'dist/chs_protocol.js'), 'w').write(tmpl.replace('/*__OMIT3_BUNDLE__*/', bundle).replace('__BASE_URL__', BASE_URL))

# standalone test page (served from the repo root; ?version=V3&why=0&base=...)
index = open(os.path.join(ROOT, 'src/index_template.html')).read().replace('__BASE_URL__', BASE_URL)
open(os.path.join(ROOT, 'index.html'), 'w').write(index)
print('built dist/ with BASE_URL =', BASE_URL, '| icons:', len(icons))
