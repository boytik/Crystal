# OUR DAYS: EASY NOW
## Product Roadmap & Improvement Plan

**From MVP to App Store Success**
Version 1.0 → 2.0 → 3.0 | February 2026

---

## 1. Executive Summary

Our Days: Easy Now is a family contribution tracker that helps parents log daily care and household tasks, see each member's contributions without toxic comparisons, and build teamwork. The current MVP (v1.0) establishes the core logging loop with gamification, dark premium aesthetics, and fully offline local storage.

*This roadmap outlines three release phases to take the app from MVP to a polished, App Store-ready product that delights users and passes Apple's review guidelines.*

### Current State Assessment

| Strengths | Gaps | Risks | Opportunities |
|-----------|------|-------|---------------|
| 1-tap logging | No accessibility audit | App Review rejection (metadata, crashes) | Parenting niche underserved |
| Dark premium UI | No Widgets / Watch | User drop-off without reminders | Shared device pairing |
| Gamification (sparks, badges, clan levels) | No iCloud sync | Data loss without backup | Apple Watch quick-log |
| Full offline / privacy | No notifications / localization | | Widgets for habit tracking |

---

## 2. App Store Review Checklist

Before submitting, every item below must be addressed. Apple rejects apps for even minor oversights.

### 2.1 Critical (Blockers)

- **App Icon:** Design 1024×1024 icon. Use the flame/house motif on dark background with gold accent. Export all required sizes via asset catalog.
- **Launch Screen:** Replace code-based splash with a proper LaunchScreen.storyboard (static, no animations). Keep animated splash as a secondary layer after launch.
- **Privacy Policy URL:** Required for any app. Host a simple page explaining: no data collection, everything local, no analytics.
- **App Description & Screenshots:** Write compelling description (4000 chars). Generate 6.7" and 5.5" screenshots. Localize at minimum for English.
- **Crash-Free Launch:** Test on physical devices: iPhone SE (2nd), iPhone 14, iPhone 15 Pro. Fix any crash in first 10 seconds.
- **Info.plist Permissions:** Remove any unused permission keys. App uses no camera/location/contacts, so plist must be clean.

### 2.2 High Priority (Common Rejections)

- **Minimum Functionality:** Apple may reject "too simple" apps. Ensure all 4 tabs have substantive content. The gamification layer helps here.
- **Empty States:** Every screen must handle zero-data gracefully. No blank screens, no broken layouts.
- **Keyboard Handling:** All TextFields must scroll into view when keyboard appears. Test on smallest screen (iPhone SE).
- **Dynamic Type:** Support at least Large and Accessibility Large font sizes. Test with Settings → Accessibility → Larger Text.
- **Dark Mode Only:** Since we force .dark, ensure no white-on-white or invisible elements anywhere.
- **Portrait Lock:** Already implemented. Verify it works on all device sizes.

### 2.3 Polish (Improves Approval Odds)

- **VoiceOver:** Add accessibility labels to all interactive elements, especially the donut chart, heatmap, and emoji grids.
- **Reduce Motion:** Respect `@Environment(\.accessibilityReduceMotion)`. Disable particle effects and spring animations.
- **Loading States:** Already implemented with skeletons. Verify they display correctly.
- **Error Handling:** Add error states for JSON load failures with "Retry" buttons.

---

## 3. Phase 1 — v1.1 Polish Release (2–3 weeks)

**Goal:** Pass App Store review, fix all UX issues, add essential missing features.

| Priority | Feature / Fix | Details | Effort |
|----------|---------------|---------|--------|
| 🔴 P0 | LaunchScreen.storyboard | Static launch screen for App Store compliance | 2 hours |
| 🔴 P0 | App Icon (all sizes) | 1024px master, asset catalog generation | 4 hours |
| 🔴 P0 | Privacy Policy page | Simple hosted HTML, link in Settings & App Store | 2 hours |
| 🔴 P0 | Crash testing on 3+ devices | iPhone SE 2, iPhone 14, iPhone 15 Pro | 1 day |
| 🟡 P1 | Haptic Feedback | UIImpactFeedbackGenerator on deed tap, moment log, gratitude | 3 hours |
| 🟡 P1 | Keyboard avoidance | ScrollViewReader + .onSubmit for all TextFields | 4 hours |
| 🟡 P1 | Accessibility labels | VoiceOver for charts, badges, emoji grids, buttons | 1 day |
| 🟡 P1 | Reduce Motion support | Disable particles, springs when enabled | 3 hours |
| 🟡 P1 | Undo toast reliability | Test undo flow, ensure moment deletion + re-add works | 3 hours |
| 🟡 P1 | Dynamic Type testing | Fix layouts breaking at XXL text sizes | 4 hours |
| 🟢 P2 | Sound effects | Subtle chime on log, gratitude, badge unlock | 3 hours |
| 🟢 P2 | Confetti on badge unlock | Re-use spark burst from splash | 2 hours |
| 🟢 P2 | Onboarding skip option | Allow power users to skip directly to main app | 1 hour |
| 🟢 P2 | Rate limiting deed taps | Prevent accidental double-logs within 1 second | 1 hour |

---

## 4. Phase 2 — v1.5 Engagement Release (4–6 weeks)

**Goal:** Increase retention, add features users expect from a modern iOS app, expand gamification.

### 4.1 Notifications & Reminders

- **Daily reminder:** Configurable time (default 8pm). "Don't forget to log today's moments!" Soft, non-pushy tone.
- **Weekly summary push:** Sunday evening notification with weekly stats preview. Taps open Bond Glance tab.
- **Streak at risk:** "Your 7-day streak is at risk! Log a moment to keep it alive." Only after 3+ day streaks.
- **Badge unlock celebration:** Rich notification with badge emoji and title when earned.

### 4.2 Widgets

- **Small Widget:** Today's moment count + current streak. Tap opens Hearth tab.
- **Medium Widget:** Quick-action buttons for top 3 deeds. Direct-to-log deep links.
- **Lock Screen Widget:** Streak flame + count. Minimal, glanceable.

### 4.3 Apple Watch App (Lite)

- **Quick log:** Digital Crown to select deed → tap member → done. Under 3 seconds.
- **Complication:** Today's count + streak on watch face.
- **Sync:** WatchConnectivity to sync moments bidirectionally with phone.

### 4.4 Enhanced Gamification

- **Weekly challenges:** "Log 5 different actions this week", "Earn 3 gratitude sparks." Rotating, auto-generated.
- **Milestone animations:** Special full-screen celebration at 50, 100, 500, 1000 moments.
- **Seasonal badges:** Time-limited badges (Holiday Helper, Summer Active, Back-to-School).
- **Family motto:** Editable family motto displayed on Clan tab. Fun personalization.

### 4.5 Data Safety & Backup

- **iCloud backup:** Optional CloudKit sync. "Your data, your choice" toggle in settings.
- **Export to PDF:** Beautifully formatted weekly/monthly report. Branded with app colors.
- **Import/Restore:** JSON import for device migration. QR code pairing between family devices.

---

## 5. Phase 3 — v2.0 Growth Release (8–12 weeks)

**Goal:** Monetization, shared family experience, AI insights, broader audience.

### 5.1 Shared Family (Multi-Device)

- **Family sharing via iCloud:** Each member on their own device, shared CloudKit container. Real-time sync.
- **Invite flow:** Share link / QR code to join family. Automatic member creation.
- **Conflict resolution:** Last-write-wins with merge for offline edits. Show sync status indicator.
- **Push notifications:** "Partner just logged: Bathed at 7:30pm." Real-time visibility.

### 5.2 AI-Powered Insights

- **Smart suggestions:** On-device ML to detect patterns. "You usually cook on Mondays — want a reminder?"
- **Weekly narrative:** Auto-generated summary in natural language. "This week the team handled 34 moments. Sarah took on most of the bedtime routine..."
- **Balance predictions:** "Based on recent trends, Thursday might be heavy for cooking — plan ahead?"
- **Burnout detection:** If one member's load increases 40%+ over 2 weeks, gentle alert: "Consider sharing the load."

### 5.3 Monetization (Freemium)

- **Free tier:** 2 members, 5 deeds, basic weekly summary, all core logging features.
- **Premium ($2.99/month or $24.99/year):** Unlimited members & deeds, advanced charts, PDF export, AI insights, custom themes, Apple Watch, Widgets.
- **Family plan ($4.99/month):** Premium for up to 6 family members on separate devices with real-time sync.
- **No ads ever:** Core brand promise. Revenue from subscriptions only.

### 5.4 Localization

- **Phase 1 languages:** Russian, German, Spanish, French (largest parent demographics).
- **Approach:** String catalogs (Xcode 15+). Professional translation + community review.
- **RTL support:** Arabic, Hebrew in Phase 2 localization wave.

### 5.5 iPad & Mac (Catalyst / Designed for iPad)

- **iPad layout:** Sidebar navigation replacing tab bar. Two-column view: deed grid + live feed.
- **Mac Catalyst:** Menu bar quick-log. Keyboard shortcuts for power users.

---

## 6. UX Improvements (All Phases)

These improvements should be woven into each release, not saved for a single sprint.

### 6.1 Onboarding Refinements

- **Progressive disclosure:** Show only essential setup first (2 members + 5 deeds). Reveal advanced features over first week.
- **Interactive tutorial:** Pulsing highlights on first Hearth visit: "Tap here to log your first moment."
- **Sample data option:** "See how it works" button loads 1 week of demo data. User can clear anytime.
- **Skip confirmation:** "Are you sure? You can set up your team later in Clan."

### 6.2 Hearth (Today) Tab

- **Long-press deed:** Context menu with "Log for different time", "Log with note", "Log for multiple members."
- **Drag-to-reorder deeds:** Let users arrange their most-used actions at the top.
- **Quick gratitude:** Swipe right on a recent moment to send thanks, with heart animation.
- **Today's hero banner:** "Most active today: Partner (5 moments)" with emoji and gold accent.
- **Deed usage heat:** Deeds with higher weekly count show warmer glow intensity.

### 6.3 Tale Scroll (Feed) Tab

- **Inline editing:** Tap time to edit inline, tap note to add/edit. No sheet needed for quick fixes.
- **Batch actions:** Select multiple moments for bulk delete or bulk gratitude.
- **Timeline view:** Optional vertical timeline visualization (like Git log) alongside list view.
- **Photo attachments:** Optional photo per moment (baby's bath, cooked meal). Local only.

### 6.4 Bond Glance (Summary) Tab

- **Animated chart transitions:** Charts morph when switching week → month with smooth interpolation.
- **Comparison mode:** This week vs. last week side-by-side (opt-in, respects soft mode).
- **Trend arrows:** "Up 12% from last week" on key metrics. Green/red subtle indicators.
- **Shareable summary card:** Generate beautiful image card (like Spotify Wrapped) for sharing.

### 6.5 Clan Nook (Settings) Tab

- **Member profiles:** Tap member to see their all-time stats, top deeds, streaks, badges.
- **Deed templates:** "Baby Care Pack", "Household Essentials", "School Routine" — pre-made deed sets.
- **Theme customization:** Accent color picker (gold default, allow teal/purple/rose). Keep dark background.
- **Data health indicator:** Show storage usage, last backup date, data integrity check.

---

## 7. Technical Debt & Architecture

### 7.1 Must Fix Before v1.1

- **Thread safety:** HearthVault publishes from background queue in saveArray. Wrap all @Published updates in MainActor.
- **Memory leaks:** Audit all [weak self] captures in Combine sinks and closures.
- **JSON migration strategy:** Version the JSON schema. Add migration code for when model properties change between updates.
- **Unit tests:** At minimum: HearthVault CRUD, spark calculations, badge unlock logic, date helpers.
- **UI tests:** Snapshot tests for all 4 tabs in light/dark (even though dark-only, test edge cases).

### 7.2 Architecture Evolution

- **Repository pattern:** Extract HearthVault into protocol-based repositories (KinSoulRepository, EmberMomentRepository) for testability.
- **Dependency injection:** Replace HearthVault.shared singletons with environment-injected dependencies.
- **SwiftData migration:** When dropping iOS 16 support, migrate from JSON to SwiftData for better query performance.
- **Modularization:** Split into SPM packages: Models, Storage, UI, Gamification. Enables faster builds and future sharing.
- **CI/CD:** GitHub Actions: build, test, lint (SwiftLint), screenshot generation, TestFlight upload.

---

## 8. Release Timeline

| Version | Target | Key Deliverables | Goal |
|---------|--------|------------------|------|
| v1.1 | March 2026 | App Store launch, icons, accessibility, haptics, crash fixes | Pass Review |
| v1.2 | April 2026 | Notifications, Widgets, sound effects, bug fixes from v1.1 feedback | Retention |
| v1.5 | June 2026 | Apple Watch, enhanced gamification, iCloud backup, PDF export | Engagement |
| v2.0 | Sep 2026 | Multi-device sync, AI insights, freemium, localization (4 languages) | Growth |
| v2.5 | Dec 2026 | iPad, Mac Catalyst, photo attachments, advanced analytics | Platform |
| v3.0 | Q1 2027 | Family plan, real-time push, sharing features, seasonal events | Revenue |

---

## 9. Success Metrics

Track these KPIs from day one to measure whether the roadmap is delivering value.

| Metric | v1.1 Target | v1.5 Target | v2.0 Target |
|--------|-------------|-------------|-------------|
| Day 1 Retention | 40% | 55% | 65% |
| Day 7 Retention | 20% | 35% | 45% |
| Day 30 Retention | 10% | 20% | 30% |
| Avg. moments/day/user | 2 | 4 | 6 |
| App Store Rating | 4.0+ | 4.3+ | 4.5+ |
| Crash-free rate | 99% | 99.5% | 99.9% |
| Premium conversion | — | 5% | 8% |
| Weekly active users | Baseline | 2× | 5× |

---

## 10. Top 10 Recommendations

If you had to pick only ten things to do next, these are the highest-impact actions:

1. **Create LaunchScreen.storyboard + App Icon** — Without these, Apple will reject the app immediately. Do this first.
2. **Add haptic feedback everywhere** — Taptic engine feedback transforms perceived quality. Users feel the app is "premium."
3. **Implement local notifications** — Reminders are the #1 driver of daily habit formation. Without them, users forget the app exists.
4. **Build Home Screen Widget** — Widgets keep the app visible. A streak counter on the home screen is a powerful retention tool.
5. **Add sound design** — Subtle chimes on log, badge unlock, and gratitude create emotional reward loops.
6. **Write unit tests for HearthVault** — The data layer is the foundation. One corruption bug destroys trust. Tests prevent this.
7. **Create shareable summary cards** — Users sharing their weekly summary = free organic marketing. Make it beautiful and branded.
8. **Plan JSON schema versioning** — When you ship an update that changes models, existing users' data must migrate cleanly.
9. **Submit to App Store ASAP** — Real user feedback is 10× more valuable than planning. Ship v1.1, iterate fast based on reviews.
10. **Build the Apple Watch app** — Parents' hands are full. Wrist-based logging removes the last friction barrier.

---

> *Every moment matters. Ship fast, iterate often, listen to families.* 🔥
