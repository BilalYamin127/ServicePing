# Google Play Data safety — ServicePing 1.0.0

Prepared from the current app source, package dependencies and release manifest on 6 November 2026. Use these facts when completing the actual Play Console form; review again if you add an SDK, network service, crash reporting, ads, support form or synchronization.

| Console topic | Current-build answer / evidence |
| --- | --- |
| Does the app collect or share user data off-device? | **No.** The app has no developer backend, network API, analytics or advertising service. Garage records are processed locally. |
| Local information handled | Vehicle details, optional registration, readings/history, service dates/types/costs/notes, schedules and theme preference. These stay on-device. |
| Why local records are not listed as transmitted collection | Google's Data safety guidance distinguishes on-device processing from data sent off-device. Do not mark a locally stored cost as transmitted financial data when this build does not transmit it. |
| Third-party sharing | None by the app. Operating-system and app-store services have their own policies. |
| Advertising identifier or tracking | Not accessed. No advertising SDK or cross-app tracking. |
| Location, contacts, photos, microphone | Not accessed. No GPS or telematics; mileage is entered manually. |
| Account creation | None. All features work without signing in. Account-deletion URL requirements tied to in-app account creation do not apply to this build. |
| Deleting records | Users can delete records/vehicles/schedules. Deleting a vehicle removes associated active data. Clear app data or uninstall to remove the local garage; independent OS backups must be managed separately. |
| Encryption in transit | Not applicable to garage records because the app transmits none. If the form hides this question after choosing “No data collected,” leave it hidden. Do not claim a transport-encryption service that the app does not have. |
| At-rest / end-to-end encryption | No extra app-level Hive encryption key is configured. Relying on the OS sandbox does not justify claiming end-to-end encryption. |
| Independent security review / certification | Do not claim certification or an independent review. None was performed. |
| Notification permission | Optional POST_NOTIFICATIONS; used for local date reminders. Android RECEIVE_BOOT_COMPLETED restores alarms after restart/update. |
| Support email | Outside the app, at the user's choice. Replace the reserved placeholder with your own monitored mailbox before publishing. |
| Privacy policy | Present in-app under Settings, plus an HTML copy to host at a publicly accessible HTTPS URL. DOCX and PDF are editing/review copies, not the public policy URL. |

## Other App content forms

- **Ads:** No ads in the current build.
- **App access:** All features are available without special access, reviewer login, payment or an invitation.
- **Content rating:** Utility app with no user chat, public posting, gambling, sexual content or violence. Complete the official questionnaire; its result determines the rating.
- **Audience:** Suggested intended users are people aged 16+ who manage cars or motorcycles. Confirm your actual target age groups. The app is not designed specifically for children.
- **Financial features:** Maintenance expense entry is a local record-keeping feature, not lending, banking, investment, payment processing or insurance.
- **Health features:** None.
- **Privacy policy operator:** Match the developer/brand identity you use in Play Console; the policy explicitly names ServicePing.

## Primary references

- [Google Play Data safety form guidance](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en)
- [Google Play User Data / privacy policy requirements](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en)
- [Create and set up an app](https://support.google.com/googleplay/android-developer/answer/9859152?hl=en)

This file is a form-completion guide for the current implementation, not a declaration submitted to Google Play. No Console form has been submitted on your behalf.
