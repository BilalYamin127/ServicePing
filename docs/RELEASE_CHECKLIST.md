# Release verification

- Run formatting, analysis and all tests.
- Build and install on a physical Android phone and iPhone.
- Create a car and motorcycle with different units; restart and verify saved state.
- Exercise create/edit/delete for vehicles, records and schedules.
- Verify negative/invalid numbers and decreasing odometer readings are blocked.
- Verify due-today, overdue-date, equal-mileage and exceeded-mileage statuses.
- Record a completed schedule and verify both schedule history and service history.
- Deny/allow notifications, test a future reminder, reboot Android, test device timezone changes.
- Verify accessibility text scaling and small screens.
- Verify branded launcher icons on Android and iOS; review launch art on target devices.
- Replace the temporary email in store/source/policy.json, regenerate policy documents, rebuild the app and host the HTML policy at a public HTTPS URL.
- Check Settings → Privacy policy works offline and matches the hosted policy.
- Use store/UPLOAD-GUIDE.md for graphics, listing text and Data safety facts.
- Configure release application IDs, Android release keystore, Apple development team and store metadata.
- Review third-party package licenses and create the required store privacy declarations.
- Build signed AAB/IPA; test the signed build before uploading.
