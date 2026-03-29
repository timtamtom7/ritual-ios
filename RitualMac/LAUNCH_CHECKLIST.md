# RitualMac — Launch Checklist

## Pre-Launch

### Code & Quality
- [ ] Build succeeds (`xcodebuild -scheme RitualMac -configuration Release`)
- [ ] All colors use `MacTheme` tokens (no hardcoded hex in views)
- [ ] Dark mode verified: backgrounds `#0D0B09`, text `#F5F0E8`, accent `#C9A96E`
- [ ] No runtime warnings in Console.app
- [ ] Memory usage acceptable (no leaks in Instruments)

### App Store
- [ ] App Store Connect account set up with Mac developer program
- [ ] Bundle ID registered (`com.ritual.mac`)
- [ ] App icon uploaded (`AppIcon.png`, 1024×1024)
- [ ] Screenshots captured:
  - [ ] Hero: Morning Intention + breathing circle
  - [ ] Evening Check-In flow
  - [ ] Today's Rituals list
- [ ] Tagline written: " Rituals that stick."
- [ ] Description written (warm, non-gamified tone)
- [ ] Keywords list added
- [ ] Category selected: Lifestyle / Health & Fitness

### Entitlements
- [ ] App Sandbox enabled
- [ ] Hardened Runtime enabled
- [ ] App Store receipt validation handled
- [ ] Network access for AI features (if applicable)
- [ ] File access for local data storage

### Privacy & Legal
- [ ] Privacy manifest (`PrivacyInfo.xcprivacy`)
- [ ] No tracking — confirm analytics are local-only
- [ ] Terms of Service page hosted
- [ ] Privacy Policy page hosted
- [ ] Age rating: 4+ (no age restrictions)

---

## Launch Day

- [ ] Version bumped to `1.0.0`
- [ ] Build number incremented
- [ ] Build submitted via Xcode Organizer or `xcrun altool`
- [ ] Submission note: "RitualMac — mindful intention-setting for macOS"
- [ ] Wait for App Store review (typically 1-3 days for Mac apps)

---

## Post-Launch

- [ ] Verify app appears on App Store
- [ ] Test purchase flow (if paid / IAP)
- [ ] Monitor for crash reports in App Store Connect
- [ ] Share on social media / relevant communities
- [ ] Set up TestFlight for future beta releases
- [ ] Create feedback email alias (e.g., feedback@ritualapp.com)

---

## Future Releases

- [ ] Version bump in `project.yml` and `Info.plist`
- [ ] Update `CHANGELOG.md`
- [ ] Run full build test before submission
- [ ] Review App Store review guidelines for any new rules
