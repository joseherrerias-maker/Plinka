#!/usr/bin/env python3
"""Build an offline HTML gallery and one contact sheet per device."""
import html, json, sys
from pathlib import Path
from PIL import Image, ImageDraw
root=Path(sys.argv[1]); sections=[]; total=0
for folder in sorted(root.iterdir()):
    if not folder.is_dir(): continue
    pictures=sorted(folder.glob('*.png'))
    if not pictures: continue
    device=json.loads((folder/'device.json').read_text()) if (folder/'device.json').exists() else {'device':folder.name,'runtime':'incomplete'}
    cards=[]; sheet=Image.new('RGB',(1200,4*480),'#eff6f5'); draw=ImageDraw.Draw(sheet)
    for i,p in enumerate(pictures):
        with Image.open(p) as source:
            im=source.convert('RGB')
            if p.stem.startswith('landscape') and im.height > im.width:
                im=im.transpose(Image.Transpose.ROTATE_270)
                im.save(p)
            im.thumbnail((280,420))
            x=(i%4)*300+(300-im.width)//2; y=(i//4)*480+45
            sheet.paste(im,(x,y)); draw.text(((i%4)*300+8,(i//4)*480+8),p.stem,fill='#203952')
        url=html.escape(p.relative_to(root).as_posix())
        cards.append(f'<figure><a href="{url}"><img loading="lazy" src="{url}"></a><figcaption>{html.escape(p.stem)}</figcaption></figure>')
    sheet.save(root/(folder.name+'-contact-sheet.jpg'),quality=88)
    sections.append('<h2>'+html.escape(device['device'])+'</h2><p>'+html.escape(device['runtime'])+'</p><div class="grid">'+''.join(cards)+'</div>');total+=len(pictures)
(root/'index.html').write_text('''<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Pluki visual review</title><style>body{font:16px system-ui;background:#eff6f5;color:#203952;margin:24px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:16px}figure{margin:0;background:white;padding:12px;border-radius:16px}img{width:100%;height:400px;object-fit:contain}figcaption{margin:12px 0}h2{margin-top:48px}</style><h1>Pluki visual review</h1><p>Real simulator screenshots. Capture success does not imply visual approval. Inspect clipping, controls, keyboard, safe areas and sheet layout. These are standard-text full-screen layouts; accessibility text and iPad multitasking remain separate checks.</p>'''+''.join(sections))
(root/'REVIEW.txt').write_text(f'{total}/96 screenshots captured. Human visual approval pending.\nInspect each device in both orientations. Full-screen standard-text coverage only.\n')
if total != 96: raise SystemExit(f'Incomplete report: {total}/96 screenshots')
