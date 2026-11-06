# ServicePing — upload guide / upload karne ka tareeqa

Sab assets is `store/` folder mein hain. Doosri device par GitHub se **ServicePing-Store-Kit.zip** download aur extract kar lein. ZIP ko Play Console mein upload nahin karna: andar ke individual PNG aur text fields use karne hain.

## 1. Pehle preview check karein

- `asset-overview.png`: logo, feature graphic aur tamam 7 screenshots ka ek preview.
- `review-gallery.html`: download karke browser mein offline khol sakte hain.
- `branding/app-icon-512.png`: Google Play icon, exactly 512 × 512.
- `branding/app-icon-1024.png`: high-resolution app icon, exactly 1024 × 1024.
- `branding/feature-graphic-1024x500.png`: feature graphic, exactly 1024 × 500.
- `screenshots/play-store/`: 7 final portrait screenshots, each 1080 × 1920. Numbered order mein upload karein.
- `screenshots/raw/`: real Flutter UI captures. Reference aur redesign ke liye; final upload files `play-store/` folder mein hain.

Screenshots mein fictional demo data hai. App ki production installation mein yeh demo vehicles/records add nahin hote. The UI captures are genuine Flutter widgets; only the surrounding marketing layout and phone frame were added.

## 2. Temporary email replace karein

Abhi email **support@serviceping.example** hai. `.example` reserved placeholder hai; is par email deliver nahin hogi.

1. `store/source/policy.json` mein `contact_email` apne monitored support email se replace karein.
2. `contact_is_placeholder` ko `false` karein. Zarurat ho to `operator` apne Play Console developer display name se match karein aur effective date update karein.
3. `python3 tool/build_store_documents.py` chala dein. Is se privacy DOCX/PDF/HTML/TXT/MD, public webpage aur full store-listing documents update ho jayenge.
4. Generator `store/listing/store-fields.json` ka support email bhi update kar deta hai. Is JSON ko Console mein import karna required nahin; yeh field reference hai. Privacy URL hosting ke baad manually set karein.
5. App dobara build karein: in-app policy bhi isi `policy.json` se load hoti hai.
6. `python3 tool/package_store_kit.py` se updated ZIP aur checksums bana lein.

Word mein sirf DOCX edit karne se app aur HTML copy automatically update nahin hoti; consistent update ke liye JSON + generator use karein.

## 3. Privacy policy URL live karein

Google Play ko public, accessible HTTPS HTML webpage chahiye. Policy ka DOCX/PDF ya GitHub source-file view is ka substitute nahin hai.

Web-ready file: `docs/privacy/index.html` (same content as `store/privacy/privacy-policy.html`). Abhi hosting enable ya public policy deploy nahin ki gayi.

GitHub Pages use karna ho to contact replace karne ke baad repository **Settings → Pages → Deploy from a branch → main → /docs → Save** select karein, agar aapke repository/account par yeh option available ho. Deployment ke baad URL verify karein. Is repository ke default Pages address par expected path `https://bilalyamin127.github.io/ServicePing/privacy/` hoga; yeh abhi live URL ka claim nahin hai. Custom domain/settings hon to actual URL different ho sakta hai.

Live URL ko `store/listing/store-fields.json` aur Play Console ke Privacy policy field mein daalein. Browser incognito se bina login khol kar check karein.

## 4. Play Console → Main store listing

| Field | File / value |
| --- | --- |
| Default language | English (United States), en-US |
| App name | `listing/app-name.txt` |
| Short description | `listing/short-description.txt` |
| Full description | `listing/full-description.txt` |
| App category | Auto & Vehicles |
| App icon | `branding/app-icon-512.png` |
| Feature graphic | `branding/feature-graphic-1024x500.png` |
| Phone screenshots | `screenshots/play-store/01-dashboard.png` through `07-dark-mode.png` |
| Support email | Apna real monitored email |
| Privacy policy | Apna live public HTTPS HTML URL |
| Developer website / phone | Optional fields ko blank rakh sakte hain jab tak real details available na hon; verified account details apne Console account mein complete karein. |

Complete listing ki editable copy `listing/complete-store-listing.docx` hai; readable PDF aur Markdown bhi saath hain. App name 30-character, short description 80-character aur full description 4,000-character limits ke andar hain.

## 5. App content aur release

- `listing/data-safety-guide.md` use karke current build ke mutabiq forms fill karein: no off-device collection/sharing, no ads, no login, manual mileage.
- App access unrestricted hai; reviewer credentials required nahin.
- Target audience aur content-rating questionnaire apne actual intended users ke mutabiq complete karein. Rating Google determine karta hai.
- Release notes `listing/release-notes.txt` se copy karein.
- Signed **release AAB** upload karein. Debug APK sirf testing ke liye hai; production upload ke liye apni signing configuration use karein.
- Physical phone par notification permission, reminder delivery, new launcher icon aur offline privacy screen verify karein.
- Publish karne se pehle placeholder email aur unpublished policy URL ko replace karna zaroori hai. Kisi Play Console listing ya privacy site ko is task mein publish nahin kiya gaya.

## Rebuild visuals (optional)

```sh
python3 -m pip install playwright python-docx reportlab Pillow
python3 -m playwright install chromium --only-shell
# From the Flutter project root:
SERVICEPING_CAPTURE_FONT="$PWD/store/source/Roboto.ttf" flutter test tool/capture_store_screenshots_test.dart
python3 tool/build_store_assets.py
python3 tool/build_store_documents.py
python3 tool/package_store_kit.py
```

`source/*.html` are self-contained, editable graphic layouts; the font files and their OFL licenses are included. Font/image resizing and screenshot framing do not modify the captured Flutter UI. Original generated logo master is preserved.

## Official upload specifications

Checked on 6 November 2026:

- [Google Play preview asset specifications](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en)
- [Google Play privacy policy requirements](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en)
- [Google Play Data safety guidance](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)
