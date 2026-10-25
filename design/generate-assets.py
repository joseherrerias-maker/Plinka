"""Historical Pluki V2 vector generator; replaced stickers are protected."""
from pathlib import Path
import json, subprocess
root=Path(__file__).resolve().parent
assets=root.parent/'ios/Plinka/Assets.xcassets'
def svg(body, w=128, h=128):
 return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><defs><linearGradient id="shine" x2="0.3" y2="1"><stop stop-color="white" stop-opacity=".48"/><stop offset="1" stop-color="white" stop-opacity="0"/></linearGradient></defs>{body}</svg>'''
def rect(x,y,w,h,c,r=5):return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{c}"/>'
def line(x,y,a,b,c='#243651',w=3):return f'<path d="M{x} {y}L{a} {b}" stroke="{c}" stroke-width="{w}" stroke-linecap="round"/>'
def circle(x,y,r,c):return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{c}"/>'
def keys(x,y,width,height):
 s=rect(x,y,width,height,'#fffaf0',3)
 for i in range(1,7):s+=line(x+width*i/7,y,x+width*i/7,y+height,'#bcc9cf',1)
 for i in [1,2,4,5,6]:s+=rect(x+width*i/7-3,y,6,height*.58,'#243651',1)
 return s
art={}
art['piano']='<path d="M27 72V39Q27 24 47 24H85Q107 24 103 44L87 72Z" fill="#263a59" stroke="#172842" stroke-width="3"/>'+line(34,88,30,110,w=7)+line(93,88,98,110,w=7)+rect(20,68,89,29,'#364f72',8)+keys(24,73,81,18)+'<path d="M32 42Q33 31 48 31H91" fill="none" stroke="#758ca5" stroke-width="4" stroke-linecap="round"/>'
art['xylophone']=line(23,100,105,100,'#9a664b',8)
for i,c in enumerate(['#fb6b78','#ffb644','#f4da52','#6ecaa0','#62bde8','#a589e6']):
 y=30+i*4; art['xylophone']+=rect(15+i*16,y,14,76-i*8,c,5)+circle(22+i*16,y+9,2,'#fff6e6')
art['xylophone']+=line(22,19,91,43,'#d6a575',4)+circle(20,18,7,'#f9dfb0')
art['guitar']='<g transform="rotate(31 64 64)">'+line(64,23,64,66,'#9b4f35',12)+rect(56,7,16,22,'#b96b47',5)+'<path d="M51 54Q35 49 37 68Q21 80 32 100Q43 116 65 112Q93 111 95 90Q95 76 82 67Q86 49 69 54Z" fill="#eea44d" stroke="#d17b36" stroke-width="3"/>'+circle(64,78,11,'#854e32')+rect(50,97,28,5,'#77412e',2)+''.join(line(x,20,x,100,'#fff2ce',1) for x in [61,64,67])+ '</g>'
art['trumpet']='<path d="M20 56H65Q88 52 100 31L113 85Q92 72 65 73H42V87H70V66" fill="none" stroke="#e29b22" stroke-width="17" stroke-linejoin="round"/><path d="M20 54H65Q88 50 100 29L113 83Q92 70 65 71H42V85H70V64" fill="none" stroke="#ffc64e" stroke-width="11" stroke-linejoin="round"/>'+''.join(line(x,46,x,67,'#ffdb71',6)+rect(x-5,40,10,5,'#eda628',2) for x in [45,58,71])+line(13,48,13,64,'#e5a02c',6)
art['flute']='<g transform="rotate(40 64 64)">'+rect(53,13,22,103,'#bed5df',9)+rect(57,17,6,94,'#f8feff',3)+''.join(circle(68,y,4,'#546d86') for y in [40,54,68,82,96])+rect(51,27,26,6,'#99b5c4',2)+'</g>'
art['bells']='<path d="M24 89Q39 79 37 56Q37 27 64 27Q91 27 91 56Q89 79 104 89Z" fill="#ffc44f" stroke="#e4a02c" stroke-width="3"/>'+circle(64,23,8,'#e9a82e')+rect(22,86,84,12,'#f8b23d',6)+circle(64,101,9,'#bb7b25')+'<path d="M47 58Q46 40 58 38" stroke="#fff0b4" stroke-width="6" fill="none" stroke-linecap="round"/>'
art['synth']=rect(13,30,102,72,'#9f70db',14)+rect(18,34,92,10,'#bb92ef',5)+keys(21,58,86,36)+''.join(circle(x,49,3,'#ffe781') for x in [28,39,50])+rect(79,46,25,5,'#594c91',2)
art['drums']='<path d="M25 49H103V93Q63 111 25 93Z" fill="#fa7970" stroke="#d35151" stroke-width="3"/>'+''.join('<path d="M%d 53l13 43 13-43" fill="none" stroke="#ffe4a4" stroke-width="3"/>'%x for x in [25,51,77])+'<ellipse cx="64" cy="49" rx="41" ry="13" fill="#fff4d7" stroke="#e5ae55" stroke-width="5"/>'+line(26,19,84,44,'#c18449',5)+line(104,15,49,43,'#c18449',5)+circle(27,19,5,'#e8b775')+circle(104,15,5,'#e8b775')
# Bright animal and toy stickers share the existing editable vector style.
face=circle(64,67,39,'#b97af5')+circle(49,65,5,'#243651')+circle(79,65,5,'#243651')+circle(64,78,5,'#e94a97')+'<path d="M52 87Q64 97 76 87" fill="none" stroke="#243651" stroke-width="3" stroke-linecap="round"/>'
art['kitten']='<path d="M28 49L25 14 53 35M77 35L103 14 100 52" fill="#b97af5" stroke="#8952c5" stroke-width="4"/>'+face+circle(42,81,7,'#e8a5fa')+circle(86,81,7,'#e8a5fa')
art['puppy']=circle(64,67,39,'#ffe1a6')+'<ellipse cx="29" cy="52" rx="17" ry="32" fill="#c56a2b" transform="rotate(18 29 52)"/><ellipse cx="99" cy="52" rx="17" ry="32" fill="#c56a2b" transform="rotate(-18 99 52)"/>'+circle(50,62,5,'#243651')+circle(78,62,5,'#243651')+circle(64,80,16,'#fff6df')+circle(64,75,7,'#243651')+rect(59,87,10,13,'#ff678c',5)
art['sparkle']='<path d="M64 10L80 43 116 48 90 74 96 111 64 93 32 111 38 74 12 48 48 43Z" fill="#ffdc32" stroke="#f4ad14" stroke-width="4" stroke-linejoin="round"/>'+circle(51,62,4,'#593d32')+circle(77,62,4,'#593d32')+'<path d="M55 77Q64 85 73 77" fill="none" stroke="#593d32" stroke-width="3" stroke-linecap="round"/>'
art['boing']='<path d="M49 47Q103 51 88 64Q22 72 42 82Q105 87 83 100H44" fill="none" stroke="#8d63e8" stroke-width="9" stroke-linecap="round"/>'+circle(64,32,25,'#ff619d')+circle(55,28,4,'#243651')+circle(73,28,4,'#243651')+'<path d="M56 40Q64 46 72 40" fill="none" stroke="#243651" stroke-width="3" stroke-linecap="round"/>'+circle(51,19,6,'#ffb8d3')
# All stickers use the same transparent canvas, inset, and subtle grounding shadow.
for name,body in art.items():
 art[name]=svg('<ellipse cx="65" cy="114" rx="36" ry="5" fill="#364354" opacity=".13"/>'+body)
room='<rect width="1600" height="1000" fill="#b9e2e1"/>'
room+=rect(120,50,620,600,'#e2b68e',30)+rect(144,74,572,552,'#a4d9e6',16)
room+='<path d="M145 480Q300 270 470 440T716 370V626H145Z" fill="#8fc9b1"/>'
for x in [330,520]:room+=rect(x,74,15,552,'#e6c39a',3)
room+=rect(144,330,572,15,'#e6c39a',3)
room+=rect(1350,75,170,685,'#bc8e68',16)
for y in [220,380,540,700]:
 room+=rect(1340,y,190,18,'#956d50',3)
 for j,c in enumerate(['#dc947c','#e9c56f','#81bfb3','#819bbd']):room+=rect(1360+j*34,y-100,25,98,c,3)
room+='<path d="M0 800Q800 730 1600 800V1000H0Z" fill="#d8a779"/>'
for y in [850,920,990]:room+=line(0,y,1600,y,'#c39268',3)
room+=rect(45,600,125,190,'#5b7f82',22)+circle(108,658,33,'#365d65')+circle(108,739,22,'#365d65')
room+='<path d="M1190 0V91" stroke="#a58a62" stroke-width="6"/><path d="M1110 130Q1120 50 1190 50Q1260 50 1270 130Z" fill="#ffde89"/>'
for x,y in [(930,80),(1010,115),(850,110)]: room+='<ellipse cx="%d" cy="%d" rx="50" ry="22" fill="#74ad83" transform="rotate(-25 %d %d)"/>'%(x,y,x,y)
art['studio-room']=svg(room,1600,1000)
for name,source in art.items():
 # Build 5 stickers use the reference-matched PNG assets. This legacy generator
 # may still refresh the background, but must not restore the old icon family.
 if name != 'studio-room':
  continue
 path=root/(name+'.svg');path.write_text(source)
 folder=assets/(name+'.imageset');folder.mkdir(parents=True,exist_ok=True)
 subprocess.run(['inkscape',str(path),'--export-filename='+str(folder/(name+'.png')),'--export-width='+('1600' if name=='studio-room' else '256')],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 (folder/'Contents.json').write_text(json.dumps({'images':[{'filename':name+'.png','idiom':'universal'}],'info':{'author':'xcode','version':1}}))
print('Rendered instrument, animal, and fun stickers with studio background.')
