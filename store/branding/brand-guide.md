# ServicePing brand reference

## Identity

The speedometer, road and orange ping mark express mileage, vehicle care and reminders. The app uses manual odometer entry; the symbol does not describe GPS tracking or automatic mileage detection.

## Palette

| Role | Hex |
| --- | --- |
| Primary deep blue | `#102B55` |
| Midnight background | `#09162B` |
| Supporting blue | `#204C81` |
| Automotive orange | `#FF9446` |
| Light background | `#F3F5F9` |
| White | `#FFFFFF` |

Marketing typography: Manrope, included under the SIL Open Font License. Application screenshots use Roboto and the actual Material 3 UI. Both fonts and their licenses are included in `store/source/`.

## Logo files and use

- `logo-master.png`: original generated high-resolution artwork, preserved.
- `app-icon-1024.png`: opaque 1024 × 1024 RGB PNG (no alpha channel), suitable as the iOS source icon.
- `app-icon-512.png`: opaque 512 × 512 RGBA PNG for Google Play.
- Native Android, iOS and web icon files in the app have been replaced with matching brand exports.

Keep the symbol's proportions. The supplied store icon is square with full-bleed artwork; let each platform apply its own icon mask. Do not add a store rating, discount, rank or certification badge. When using the logo beside text, leave at least one small ping-dot width of space around it and retain strong foreground/background contrast.

The rendered marketing layout sources are in `store/source/*.html`. Regenerate them with `tool/build_store_assets.py` after recapturing the app. All promotional statements refer to implemented app features; the sample garage exists only in the capture tool.
