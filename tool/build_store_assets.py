"""Export exact-size store assets from the original logo and real Flutter captures.
Requires: pip install playwright; python -m playwright install chromium --only-shell
No screenshot UI is recreated or retouched: captures are only scaled into layouts.
"""
from pathlib import Path
import base64
import json
from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
STORE = ROOT / 'store'

def data_uri(path):
    mime = 'font/ttf' if path.suffix == '.ttf' else 'image/png'
    return f'data:{mime};base64,' + base64.b64encode(path.read_bytes()).decode()

PAGES = [
 ('01-dashboard', 'Every vehicle.<br>One clear view.', 'Your mileage, service dates and next steps. Together.'),
 ('02-garage', 'Your whole garage.<br>In one place.', 'Cars and motorcycles. A separate story for each.'),
 ('03-schedules', 'Know what’s due.<br>Keep moving.', 'Plan by date, mileage, or both. See overdue work.'),
 ('04-history', 'Every service.<br>A clear history.', 'Find the work, mileage and costs that matter.'),
 ('05-statistics', 'See where your<br>money goes.', 'Turn maintenance records into monthly insights.'),
 ('06-manual-odometer', 'Your mileage.<br>Your control.', 'Manual readings. Decrease protection. Clear history.'),
 ('07-dark-mode', 'Day or night.<br>Always ready.', 'Light and dark themes. Offline, without an account.'),
]

CSS = '''
@font-face{font-family:Manrope;src:url(FONT) format('truetype');font-weight:200 800}
*{box-sizing:border-box}html,body{margin:0;width:100%;height:100%;overflow:hidden}
body{font-family:Manrope,sans-serif;color:white;background:#0b1b34}
.poster{width:1080px;height:1920px;position:relative;overflow:hidden;background:linear-gradient(145deg,#09162b 0%,#102b55 75%,#173b66 100%)}
.orbit{position:absolute;width:1580px;height:1580px;left:-250px;top:520px;border-radius:50%;border:1px solid #ffffff0b;box-shadow:0 0 0 80px #ffffff03,0 0 0 160px #ffffff03,0 0 0 240px #ffffff02}
.glow{position:absolute;width:950px;height:950px;left:-600px;top:900px;background:radial-gradient(circle,#f58b3c20,transparent 65%)}
.brand{position:absolute;top:52px;left:72px;display:flex;align-items:center;gap:15px;font-size:28px;font-weight:750;letter-spacing:-.7px}.brand img{width:44px;height:44px;border-radius:10px}
.index{position:absolute;right:74px;top:68px;font-size:17px;font-weight:650;letter-spacing:3px;color:#a6bdd8}
h1{position:absolute;left:72px;top:126px;margin:0;font-size:69px;line-height:1.09;letter-spacing:-2.9px;font-weight:800;width:940px}h1 em{font-style:normal;color:#ffab67}
.subtitle{position:absolute;left:75px;top:297px;color:#c2d2e5;font-size:25px;font-weight:500;letter-spacing:-.25px;margin:0}
.phone{position:absolute;left:156px;top:363px;width:768px;height:1512px;border-radius:53px;border:2px solid #5b6c82;background:#0c131f;padding:10px;box-shadow:0 30px 90px #020711a0}
.phone img{display:block;width:744px;height:1488px;object-fit:contain;border-radius:40px;overflow:hidden}
.foot{position:absolute;bottom:12px;left:0;right:0;text-align:center;font-size:14px;letter-spacing:2.1px;color:#97afca}
'''

def html(content, width, height, css=''):
    font=data_uri(STORE/'source/Manrope.ttf')
    return f'<!doctype html><html><head><meta charset="utf-8"><style>{CSS.replace("FONT",font)}{css}</style></head><body>{content}</body></html>'


def main():
    logo=data_uri(STORE/'branding/logo-master.png')
    with sync_playwright() as p:
        browser=p.chromium.launch(headless=True,args=['--no-sandbox'])
        page=browser.new_page(device_scale_factor=1)
        # Canvas encodes an opaque RGBA PNG, with no rounded-corner mask baked in.
        targets=[('store/branding/app-icon-512.png',512),('store/branding/app-icon-1024.png',1024)]
        for dpi,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
            targets.append((f'android/app/src/main/res/mipmap-{dpi}/ic_launcher.png',size))
        spec=json.loads((ROOT/'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json').read_text())
        for entry in spec['images']:
            if 'filename' in entry:
                size=round(float(entry['size'].split('x')[0])*float(entry['scale'].rstrip('x')))
                targets.append(('ios/Runner/Assets.xcassets/AppIcon.appiconset/'+entry['filename'],size))
        targets += [('web/favicon.png',32),('web/icons/Icon-192.png',192),('web/icons/Icon-512.png',512),('web/icons/Icon-maskable-192.png',192),('web/icons/Icon-maskable-512.png',512)]
        for filename,size in targets:
            encoded=page.evaluate('''async ({src,size})=>{const image=new Image();image.src=src;await image.decode();const c=document.createElement('canvas');c.width=size;c.height=size;const ctx=c.getContext('2d');ctx.fillStyle='#102b55';ctx.fillRect(0,0,size,size);ctx.drawImage(image,0,0,size,size);return c.toDataURL('image/png').split(',')[1]}''',{'src':logo,'size':size})
            (ROOT/filename).write_bytes(base64.b64decode(encoded))
            if filename.startswith('ios/') or filename.endswith('app-icon-1024.png'):
                # Apple requires RGB icons without an alpha channel, even if opaque.
                page.set_viewport_size({'width':size,'height':size})
                page.set_content(f'<html><body style="margin:0;background:#102b55"><img style="width:100vw;height:100vh;display:block" src="data:image/png;base64,{encoded}"></body></html>')
                page.locator('img').evaluate('(image)=>image.decode()')
                page.screenshot(path=str(ROOT/filename),omit_background=False)

        for i,(name,title,subtitle) in enumerate(PAGES,1):
            raw=data_uri(STORE/f'screenshots/raw/{name}.png')
            # Emphasise the second headline line without altering the app UI.
            title=title.replace('<br>','<br><em>')+'</em>'
            content=f'<main class="poster"><div class="orbit"></div><div class="glow"></div><div class="brand"><img src="{logo}">ServicePing</div><div class="index">{i:02d} / 07</div><h1>{title}</h1><p class="subtitle">{subtitle}</p><div class="phone"><img src="{raw}"></div><div class="foot">VEHICLE MAINTENANCE, MADE CLEAR.</div></main>'
            source=html(content,1080,1920)
            (STORE/f'source/{name}.html').write_text(source)
            page.set_viewport_size({'width':1080,'height':1920});page.set_content(source)
            page.evaluate('document.fonts.ready');page.locator('.phone img').evaluate('(img)=>img.decode()')
            page.screenshot(path=str(STORE/f'screenshots/play-store/{name}.png'),omit_background=False)
        raw=data_uri(STORE/'screenshots/raw/07-dark-mode.png')
        feature_css='''body{background:#0b1b34}.feature{width:1024px;height:500px;position:relative;overflow:hidden;background:linear-gradient(115deg,#0b1a32,#15365e)}.feature .brand{left:58px;top:50px;font-size:26px}.feature .brand img{width:45px;height:45px}.feature h1{top:144px;left:58px;font-size:59px;width:560px;line-height:1.09;letter-spacing:-2px}.feature .description{position:absolute;left:62px;top:307px;color:#bacee5;font-size:20px;line-height:1.55}.feature .tag{position:absolute;left:62px;top:401px;border:1px solid #ffad6477;border-radius:40px;color:#ffb578;padding:10px 20px;font-size:15px;font-weight:750;letter-spacing:.5px}.feature .preview{position:absolute;width:278px;height:556px;left:685px;top:53px;border:7px solid #0b1321;border-radius:32px;overflow:hidden;box-shadow:0 20px 50px #02071288;transform:rotate(9deg)}.feature .preview img{width:264px;height:528px;display:block}.feature .line{position:absolute;width:750px;height:750px;border:1px solid #ffffff0b;border-radius:50%;left:450px;top:-130px;box-shadow:0 0 0 65px #ffffff03,0 0 0 130px #ffffff02}'''
        feature=f'<main class="feature"><div class="line"></div><div class="brand"><img src="{logo}">ServicePing</div><h1>Keep every<br><em>journey ready.</em></h1><p class="description">A clearer way to care for<br>your cars and motorcycles.</p><div class="tag">OFFLINE. NO ACCOUNT.</div><div class="preview"><img src="{raw}"></div></main>'
        source=html(feature,1024,500,feature_css)
        (STORE/'source/feature-graphic.html').write_text(source)
        page.set_content(source);page.set_viewport_size({'width':1024,'height':500});page.evaluate('document.fonts.ready');page.locator('.preview img').evaluate('(img)=>img.decode()')
        page.screenshot(path=str(STORE/'branding/feature-graphic-1024x500.png'),omit_background=False)
        # Contact sheet and offline review gallery make the kit easy to inspect.
        cards=''.join(f'<article><img src="{data_uri(STORE/f"screenshots/play-store/{name}.png")}"><p>{i:02d} · {name[3:].replace("-"," ").title()}</p></article>' for i,(name,_,_) in enumerate(PAGES,1))
        gallery=f'<html><head><meta charset="utf-8"><title>ServicePing · Store Asset Review</title><style>@font-face{{font-family:M;src:url({data_uri(STORE/"source/Manrope.ttf")})}}*{{box-sizing:border-box}}body{{margin:0;background:#edf1f7;color:#102b55;font-family:M,sans-serif;padding:55px}}h1{{font-size:38px;margin:0 0 12px}}.intro{{font-size:19px;margin:0 0 36px}}.hero{{display:flex;gap:30px;align-items:center;margin-bottom:40px}}.logo{{width:160px;border-radius:25px}}.feature{{width:768px;border-radius:18px}}.grid{{display:grid;grid-template-columns:repeat(4,1fr);gap:26px}}article{{margin:0}}article img{{display:block;width:100%;border-radius:14px;box-shadow:0 9px 25px #102b5520}}article p{{font-size:17px;font-weight:700}}</style></head><body><h1>ServicePing / Store kit</h1><p class="intro">Original identity · 7 real Flutter screen captures · Google Play upload sizes</p><div class="hero"><img class="logo" src="{data_uri(STORE/"branding/app-icon-512.png")}"><img class="feature" src="{data_uri(STORE/"branding/feature-graphic-1024x500.png")}"></div><div class="grid">{cards}</div></body></html>'
        (STORE/'review-gallery.html').write_text(gallery)
        page.set_content(gallery);page.set_viewport_size({'width':1600,'height':2200});page.evaluate('document.fonts.ready')
        page.screenshot(path=str(STORE/'asset-overview.png'),full_page=True)
        browser.close()
    print('Exported app icons, feature graphic, 7 store screenshots and review gallery.')

if __name__=='__main__':main()
