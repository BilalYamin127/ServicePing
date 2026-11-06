"""Build editable store documents and the offline/in-app privacy policy.
Edit store/source/policy.json, then rerun this script after changing contact details.
Requires: pip install python-docx reportlab
"""
from pathlib import Path
import json, html, base64
from datetime import date
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Image, KeepTogether
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_LEFT
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

ROOT=Path(__file__).resolve().parents[1]
STORE=ROOT/'store'
NAVY='102B55'; ORANGE='E47C30'
POLICY=json.loads((STORE/'source/policy.json').read_text())
EMAIL=POLICY['contact_email']
DRAFT=POLICY['contact_is_placeholder']


def sections():
    return [(x['title'],x['body'].replace('{operator}',POLICY['operator']).replace('{contact_email}',EMAIL)) for x in POLICY['sections']]


def word_document(path,title,subtitle,content,draft=False):
    doc=Document();sec=doc.sections[0]
    sec.top_margin=Inches(.75);sec.bottom_margin=Inches(.7)
    sec.left_margin=sec.right_margin=Inches(.85)
    normal=doc.styles['Normal'];normal.font.name='Aptos';normal.font.size=Pt(10.5);normal.font.color.rgb=RGBColor.from_string('28384C');normal.paragraph_format.space_after=Pt(8)
    for name,size in [('Title',29),('Heading 1',15),('Heading 2',12)]:
        style=doc.styles[name];style.font.name='Aptos';style.font.size=Pt(size);style.font.color.rgb=RGBColor.from_string(NAVY)
    logo=STORE/'branding/app-icon-512.png'
    if logo.exists():doc.add_picture(str(logo),width=Inches(.58))
    doc.add_heading(title,0);doc.add_paragraph(subtitle,'Subtitle')
    if draft:
        p=doc.add_paragraph();r=p.add_run('DRAFT · Replace the temporary contact email before publication.');r.bold=True;r.font.color.rgb=RGBColor.from_string(ORANGE)
    for heading,body in content:
        doc.add_heading(heading,1)
        for paragraph in body.split('\n\n'):
            doc.add_paragraph(paragraph)
    footer=sec.footer.paragraphs[0];footer.text='SERVICEPING  /  '+title.upper();footer.style=doc.styles['Caption']
    doc.core_properties.title=title;doc.core_properties.author='ServicePing';doc.save(path)


def pdf_document(path,title,subtitle,content,draft=False):
    for name,font in [('SP-Regular','DejaVuSans.ttf'),('SP-Bold','DejaVuSans-Bold.ttf')]:
        if name not in pdfmetrics.getRegisteredFontNames():pdfmetrics.registerFont(TTFont(name,'/usr/share/fonts/truetype/dejavu/'+font))
    styles=getSampleStyleSheet()
    styles.add(ParagraphStyle(name='SPTitle',fontName='SP-Bold',fontSize=26,leading=31,textColor=colors.HexColor('#'+NAVY),spaceAfter=12))
    styles.add(ParagraphStyle(name='SPSub',fontName='SP-Regular',fontSize=10,leading=15,textColor=colors.HexColor('#60748C'),spaceAfter=16))
    styles.add(ParagraphStyle(name='SPBody',fontName='SP-Regular',fontSize=9.5,leading=15,textColor=colors.HexColor('#28384C'),spaceAfter=9))
    styles.add(ParagraphStyle(name='SPHead',fontName='SP-Bold',fontSize=12,leading=17,textColor=colors.HexColor('#'+NAVY),spaceBefore=14,spaceAfter=7,keepWithNext=True))
    doc=SimpleDocTemplate(str(path),rightMargin=55,leftMargin=55,topMargin=48,bottomMargin=50,title=title,author='ServicePing')
    story=[];logo=STORE/'branding/app-icon-512.png'
    if logo.exists():story.extend([Image(str(logo),width=42,height=42,hAlign='LEFT'),Spacer(1,15)])
    story.extend([Paragraph(html.escape(title),styles['SPTitle']),Paragraph(html.escape(subtitle),styles['SPSub'])])
    if draft:story.append(Paragraph('<b>DRAFT: Replace the temporary contact email before publication.</b>',styles['SPBody']))
    for heading,body in content:
        story.append(Paragraph(html.escape(heading),styles['SPHead']))
        for p in body.split('\n\n'):
            story.append(Paragraph(html.escape(p).replace('\n','<br/>'),styles['SPBody']))
    def page_number(canvas,doc):
        canvas.setStrokeColor(colors.HexColor('#DFE6EF'));canvas.line(55,36,540,36)
        canvas.setFont('SP-Regular',8);canvas.setFillColor(colors.HexColor('#60748C'))
        canvas.drawString(55,24,'SERVICEPING  /  '+title.upper());canvas.drawRightString(540,24,str(doc.page))
    doc.build(story,onFirstPage=page_number,onLaterPages=page_number)


def main():
    fields_path=STORE/'listing/store-fields.json'
    if fields_path.exists():
        fields=json.loads(fields_path.read_text())
        fields.update(support_email=EMAIL,support_email_is_placeholder=DRAFT,version=POLICY['version'])
        fields_path.write_text(json.dumps(fields,indent=2)+'\n')
    contact_note=' — TEMPORARY; replace before submission.' if DRAFT else ''
    content=sections();date_label=date.fromisoformat(POLICY['effective_date']).strftime('%d %B %Y')
    title='ServicePing Privacy Policy';subtitle=f'Effective {date_label} · App version {POLICY["version"]}'
    draft_note='DRAFT — Temporary email address. Replace it with your monitored email before publishing.\n\n' if DRAFT else ''
    txt=title+'\n'+subtitle+'\n\n'+draft_note+'\n\n'.join(f'{i}. {heading}\n{body}' for i,(heading,body) in enumerate(content,1))+'\n'
    md='# '+title+'\n\n'+subtitle+'\n\n'+('> '+draft_note.strip()+'\n\n' if DRAFT else '')+'\n\n'.join(f'## {i}. {heading}\n\n{body}' for i,(heading,body) in enumerate(content,1))+'\n'
    (STORE/'privacy/privacy-policy.txt').write_text(txt)
    (STORE/'privacy/privacy-policy.md').write_text(md)
    logo=STORE/'branding/app-icon-512.png'
    logo_html='' if not logo.exists() else '<img class="logo" alt="ServicePing logo" src="data:image/png;base64,'+base64.b64encode(logo.read_bytes()).decode()+'">'
    paragraphs=''.join(f'<section><h2>{i}. {html.escape(h)}</h2><p>{html.escape(b)}</p></section>' for i,(h,b) in enumerate(content,1))
    badge='<p class="draft">Draft: replace support@serviceping.example with a monitored contact address before publication.</p>' if DRAFT else ''
    page=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>{title}</title><meta name="description" content="How ServicePing handles local vehicle records, maintenance reminders and privacy."><style>*{{box-sizing:border-box}}body{{margin:0;background:#f2f5fa;color:#25344a;font:16px/1.75 system-ui,-apple-system,sans-serif}}main{{max-width:850px;background:white;margin:40px auto;padding:48px;border-radius:24px}}.logo{{width:68px;border-radius:16px}}h1,h2{{color:#102b55;line-height:1.3}}h1{{font-size:36px;margin-bottom:10px}}h2{{font-size:21px;margin-top:35px}}.meta{{color:#5e7188}}.draft{{padding:15px 18px;border-left:4px solid #f58b3c;background:#fff4e9;font-weight:600}}footer{{border-top:1px solid #dce3ed;margin-top:40px;padding-top:18px;font-size:14px;color:#5e7188}}@media(max-width:700px){{main{{margin:0;padding:28px 22px;border-radius:0}}h1{{font-size:29px}}}}@media print{{body{{background:white}}main{{margin:0;padding:0;max-width:none}}}}</style></head><body><main>{logo_html}<h1>{title}</h1><p class="meta">{subtitle}</p>{badge}{paragraphs}<footer>ServicePing · Local vehicle maintenance records. This page has no analytics, cookies or remote assets.</footer></main></body></html>'''
    (STORE/'privacy/privacy-policy.html').write_text(page)
    public=ROOT/'docs/privacy';public.mkdir(parents=True,exist_ok=True);(public/'index.html').write_text(page)
    word_document(STORE/'privacy/privacy-policy.docx',title,subtitle,content,DRAFT)
    pdf_document(STORE/'privacy/privacy-policy.pdf',title,subtitle,content,DRAFT)
    listing=[
      ('Store identity',f'App name: {(STORE/"listing/app-name.txt").read_text().strip()}\nDefault language: English (United States), en-US\nApp type: App\nCategory: Auto & Vehicles\nPackage identifier: com.serviceping.service_ping\nVersion: 1.0.0 (build 1)'),
      ('Short description',(STORE/'listing/short-description.txt').read_text().strip()),
      ('Full description',(STORE/'listing/full-description.txt').read_text().strip()),
      ('Release notes — 1.0.0',(STORE/'listing/release-notes.txt').read_text().strip()),
      ('Contact and policy fields',f'Support email: {EMAIL}{contact_note}\nPrivacy policy URL: REPLACE_WITH_PUBLIC_HTTPS_PRIVACY_POLICY_URL.\nDeveloper website: optional; leave blank until you have a live support site.\nDeveloper display name, legal identity and required account contact details: use your verified Play Console information.'),
      ('Upload assets','App icon: branding/app-icon-512.png (512 × 512, opaque RGBA PNG).\nFeature graphic: branding/feature-graphic-1024x500.png (1024 × 500, RGB PNG).\nPhone screenshots: screenshots/play-store/01-dashboard.png through 07-dark-mode.png, in numbered order (each 1080 × 1920, RGB PNG).\nOriginal real Flutter captures: screenshots/raw/ (for reference; do not substitute for the numbered store layouts).'),
      ('App access and content facts','All app features are available without sign-in, an invitation, a payment or a remote account. No reviewer credentials are required. The app has no ads, purchases, user chat, public user-generated content, violence, gambling or sexual content. Suggested target audience: people aged 16 and over managing cars or motorcycles; choose the actual intended audience in Play Console. Complete the official content-rating questionnaire; the store determines the final rating. Suggested pricing: free for this version, subject to your own pricing decision.'),
      ('Data safety — current build','No user data is transmitted off-device by the app or shared with the developer or third parties. Local vehicle details, readings, service costs, notes and schedules are processed on-device. No login, ad SDK, analytics SDK or automatic mileage sensor is present. This assessment applies to the current source and dependencies; recheck it if you add network services or other SDKs. Follow the separate data-safety-guide.md for the form.'),
      ('Before uploading','Replace the temporary email in store/source/policy.json, set contact_is_placeholder to false, regenerate the documents, rebuild the app and verify the in-app policy. Host the HTML privacy policy at a public HTTPS URL and paste that live URL into Play Console. A DOCX/PDF or GitHub source-file page does not replace the required hosted policy webpage. Upload a signed release AAB; the debug APK is for testing. The generated screenshots contain fictional demo data and are not seeded into the production app.')
    ]
    md='# ServicePing — Complete Google Play Store Listing\n\n'+'\n\n'.join('## '+h+'\n\n'+b for h,b in listing)+'\n'
    (STORE/'listing/complete-store-listing.md').write_text(md)
    word_document(STORE/'listing/complete-store-listing.docx','Google Play Store Listing','ServicePing · English (United States) · Release 1.0.0',listing,DRAFT)
    pdf_document(STORE/'listing/complete-store-listing.pdf','Google Play Store Listing','ServicePing · English (United States) · Release 1.0.0',listing,DRAFT)
    for file,limit in [('app-name.txt',30),('short-description.txt',80),('full-description.txt',4000),('release-notes.txt',500)]:
        length=len((STORE/'listing'/file).read_text().strip());assert length<=limit,(file,length,limit);print(f'{file}: {length}/{limit} characters')
    print('Generated privacy TXT/MD/HTML/DOCX/PDF, public HTML source and full listing documents.')

if __name__=='__main__':main()
