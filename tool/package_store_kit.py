"""Validate and package the ready-to-download ServicePing store kit.
Requires: pip install Pillow python-docx
"""
from pathlib import Path
import hashlib,json,struct,zipfile
from PIL import Image
from docx import Document

ROOT=Path(__file__).resolve().parents[1]
STORE=ROOT/'store'

def validate():
    screenshots=sorted((STORE/'screenshots/play-store').glob('*.png'))
    assert len(screenshots)==7,'Expected exactly seven store screenshots'
    expected=[(STORE/'branding/app-icon-512.png',(512,512),'RGBA'),(STORE/'branding/app-icon-1024.png',(1024,1024),'RGB'),(STORE/'branding/feature-graphic-1024x500.png',(1024,500),'RGB')]
    expected.extend((p,(1080,1920),'RGB') for p in screenshots)
    for path in (ROOT/'ios/Runner/Assets.xcassets/AppIcon.appiconset').glob('*.png'):
        with Image.open(path) as image: assert image.mode=='RGB',('iOS icon must have no alpha channel',path)
    for path,size,mode in expected:
        with Image.open(path) as image:
            assert image.size==size,(path,image.size,size)
            assert image.mode==mode,(path,image.mode,mode)
            image.verify()
        assert path.stat().st_size<8*1024*1024,(path,'Image exceeds 8 MB')
    assert (STORE/'branding/app-icon-512.png').stat().st_size<1024*1024,'Play icon exceeds 1 MB'
    for name,limit in [('app-name.txt',30),('short-description.txt',80),('full-description.txt',4000),('release-notes.txt',500)]:
        assert len((STORE/'listing'/name).read_text().strip())<=limit,(name,limit)
    policy=json.loads((STORE/'source/policy.json').read_text())
    email=policy['contact_email']
    for name in ['privacy-policy.md','privacy-policy.txt','privacy-policy.html']:
        assert email in (STORE/'privacy'/name).read_text()
    text='\n'.join(p.text for p in Document(STORE/'privacy/privacy-policy.docx').paragraphs)
    assert email in text and 'ServicePing' in text
    assert (ROOT/'docs/privacy/index.html').read_bytes()==(STORE/'privacy/privacy-policy.html').read_bytes()
    for path in [*STORE.rglob('*.html')]:
        content=path.read_text()
        assert 'src="https://' not in content and 'src="http://' not in content,('Unexpected external asset',path)
    # Native icons must also be present at their platform sizes.
    for dpi,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
        with Image.open(ROOT/f'android/app/src/main/res/mipmap-{dpi}/ic_launcher.png') as image:assert image.size==(size,size)
    print('Validated: 7 exact-size RGB screenshots, RGB feature graphic, RGBA icons, text limits, policy consistency and offline layouts.')


def main():
    validate()
    items=[]
    for path in sorted(STORE.rglob('*')):
        if path.is_file() and path.suffix!='.zip' and path.name not in ['asset-manifest.json','SHA256SUMS.txt']:
            entry={'path':str(path.relative_to(STORE)),'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
            if path.suffix=='.png':
                with Image.open(path) as image:entry.update(width=image.width,height=image.height,mode=image.mode)
            items.append(entry)
    manifest={'app':'ServicePing','version':'1.0.0','screenshots':7,'sample_data':'Fictional; captured from the actual Flutter app in widget-render tests. Not injected into production data.','privacy_contact_is_placeholder':json.loads((STORE/'source/policy.json').read_text())['contact_is_placeholder'],'files':items}
    (STORE/'asset-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    output=STORE/'ServicePing-Store-Kit.zip'
    with zipfile.ZipFile(output,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
        for path in sorted(STORE.rglob('*')):
            if path.is_file() and path.suffix!='.zip' and path.name!='SHA256SUMS.txt':archive.write(path,path.relative_to(ROOT))
        for name in ['build_store_assets.py','build_store_documents.py','capture_store_screenshots_test.dart','package_store_kit.py']:
            archive.write(ROOT/'tool'/name,'tool/'+name)
        archive.write(ROOT/'docs/privacy/index.html','docs/privacy/index.html')
        archive.writestr('START-HERE.txt','ServicePing Store Kit\n\nOpen store/asset-overview.png for a preview.\nRead store/UPLOAD-GUIDE.md for upload instructions.\nUpload the individual PNG files from store/branding/ and store/screenshots/play-store/.\nTemporary email: support@serviceping.example — replace before publication.\nPrivacy documents: store/privacy/.\nComplete listing: store/listing/.\n')
    with zipfile.ZipFile(output) as archive:assert archive.testzip() is None
    files=[p for p in sorted(STORE.rglob('*')) if p.is_file() and p.name!='SHA256SUMS.txt']
    sums=''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+str(p.relative_to(STORE))+'\n' for p in files)
    (STORE/'SHA256SUMS.txt').write_text(sums)
    print(f'Packaged {output.name}: {output.stat().st_size / 1024 / 1024:.1f} MB. Archive integrity verified.')

if __name__=='__main__':main()
