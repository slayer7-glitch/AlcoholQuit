# Tommy — Product Requirements Document

Version: 1.0 · October 15, 2026 · Status: Proposed MVP

## 1. Product vision

Tommy is a welcoming iPhone app that helps adults stop drinking through small daily actions, practical craving support, and an encouraging cartoon superhero companion. The experience should feel calm, clear, and supportive, including after a difficult day or a return to drinking.

Working product name: Tommy. Final name and mascot artwork require trademark and cultural review before launch.

This document specifies the product; it does not represent an implemented app.

## 2. Audience and problem

Primary users are adults who want to stop drinking and need approachable daily support. Some may be starting for the first time, returning after a lapse, or using the app alongside professional treatment.

Users need to see progress without interpreting complex charts, get help during a craving in seconds, and record setbacks without feeling judged. The app must accommodate different literacy levels, disabilities, cultures, and levels of comfort discussing alcohol use.

The app is a wellness companion. It must not diagnose alcohol use disorder, prescribe treatment, or imply that it replaces medical care.

## 3. Goals and success measures

| Goal | Proposed acceptance target |
| --- | --- |
| Easy first use | At least 90% of usability participants complete onboarding without assistance in three minutes or less |
| Immediate craving support | Craving support is reachable in one tap from Home and works offline |
| Simple daily routine | A daily check-in takes under 30 seconds for at least 90% of usability participants |
| Accessible interaction | All core flows work with VoiceOver, large Dynamic Type, and Reduce Motion |
| Reliable saving | At least 99% of accepted check-ins persist successfully; pending offline saves remain visibly pending |
| Trustworthy operation | At least 99.5% crash-free sessions during beta |

Instrument onboarding completion, check-in completion, support-tool use, and aggregate retention only with appropriate consent. Establish retention baselines during beta. App engagement alone must not be presented as evidence of clinical benefit.

## 4. Experience principles

- Use everyday language, short screens, large controls, and one clear primary action per screen.
- Encourage effort and honesty. Never use shame, punishment, broken-mascot animations, or lost-access penalties after drinking.
- Keep essential support available without payment, an account, or a network connection.
- Make notifications optional and discreet. Default lock-screen wording must not disclose alcohol use.
- Prefer calm encouragement over competition, pressure, and excessive celebration.

## 5. Mascot: an inclusive cartoon superhero

The companion is a friendly, rounded cartoon superhero with a simple cape and a fictional emblem. Provide equally prominent boy and girl options, plus a skip option. Users may change their selection at any time without losing progress. Treat these as presentation choices rather than assumptions about the user's identity.

Both versions must have equal abilities, prominence, poses, and access to customization. Avoid exaggerated muscles, sexualization, weapons, national or religious symbols, and gender stereotypes. Offer a range of skin tones and hair options without charging for representation. Keep clothing modest and shapes readable at small sizes. Do not imitate existing superhero intellectual property.

No mascot can be guaranteed universally acceptable. Test proposed art and language with a diverse group of adults across cultures, genders, ages, and accessibility needs. Allow a reduced-mascot mode for people who prefer a neutral interface.

The mascot appears during onboarding, supportive check-ins, and milestones. It never diagnoses, claims to monitor safety, or implies that a lapse disappoints it. Example: “One difficult moment doesn’t erase your effort. What would help right now?”

Deliverables before implementation: character sheets for both options, customization palette, small-size icons, static and reduced-motion states, and accessible text equivalents. Animation is optional for MVP.

## 6. MVP scope and user journeys

### 6.1 Onboarding

1. Explain the app's purpose and limits in plain language.
2. Present a brief medical safety notice before encouraging a quit date. Stopping suddenly can be dangerous for people who drink heavily or have withdrawal history; advise medical guidance. Provide an always-accessible safety page.
3. Let the user choose “Start today,” a past quit date, or “I'm planning my next step.” Do not require alcohol quantity or medical history to continue.
4. Select boy superhero, girl superhero, or skip; choose appearance if desired.
5. Optionally record a personal reason for quitting and usual drink cost/spending baseline.
6. Offer optional reminders and explain notification privacy before requesting iOS permission.
7. Land on Home. Offer account creation later rather than blocking first use.

Acceptance: users can skip optional inputs, go back without losing entries, and reach Home without registering. Sensitive health information is not sent to the backend simply by opening onboarding.

### 6.2 Home and progress

Home shows a supportive greeting, progress since the chosen quit date, today's check-in, and a prominent “Help with a craving” action. Secondary progress includes alcohol-free days and estimated money saved when a baseline is supplied.

Display streaks as optional encouragement. After a drinking entry, preserve previous milestones and history. Let the user decide whether to restart the current streak; do not silently rewrite the quit date. Describe monetary figures as estimates and explain the calculation. Avoid unsupported claims about organ recovery or life expectancy.

Acceptance: future dates show planning mode rather than negative counters; date calculations respect local calendar days and daylight-saving changes; edits recalculate derived progress consistently.

### 6.3 Daily check-in

Ask “How are you feeling?” and “Did you drink today?” with “No,” “Yes,” and “Prefer not to say.” Offer optional craving intensity, triggers, and a short private note. Confirm saving clearly and support editing previous entries.

Acceptance: unanswered drinking status never counts as an alcohol-free day; repeated save taps do not create duplicates; offline entries survive app termination and synchronize later.

### 6.4 Craving support

Offer a short breathing exercise with a non-breathing grounding alternative, a five-minute urge timer, personal reasons for quitting, and a user-configured support contact. Provide a simple prompt to change surroundings or choose a safer activity.

All core exercises are bundled for offline use. Timers recover accurately after backgrounding. Calling or messaging a contact always requires an explicit user action and uses iOS system interfaces; the app never contacts someone automatically.

### 6.5 Setback support

After a drinking entry, respond neutrally, offer optional reflection, and suggest one manageable next step. Keep the journal, milestone history, and support tools available. Do not show a diagnosis, prescribe a taper, or generate individualized withdrawal advice.

### 6.6 Safety and help

Clearly explain that severe withdrawal can require emergency care. Clinically reviewed content should identify urgent warning signs such as seizures, hallucinations, or severe confusion and direct users to local emergency services. Avoid a worldwide hardcoded emergency number; localize guidance and offer a manual region choice.

Safety guidance must remain reachable from Home, craving support, and Settings, including offline. The app must never suggest that staff monitor journal entries or will dispatch help. Clinical review of safety wording is a release requirement.

### 6.7 Settings and account

Include mascot controls, reminder settings, accessibility preferences, privacy information, data export, local data erasure, and account deletion. Account sync is optional. Use Sign in with Apple for the initial cloud account flow. Clearly explain whether data is local-only, pending upload, or synchronized before the user enables cloud storage.

Users can export entries in a documented machine-readable format. Account deletion is available inside the app, immediately revokes sessions, and starts documented server-side deletion. Confirm destructive actions and explain backup retention limits.

## 7. Information architecture

Use three main tabs: Home, Progress, and Settings. Keep the daily check-in on Home and journal/history under Progress. Craving support remains prominent on Home and accessible from Progress. Avoid social feeds and deep navigation in MVP.

Core screens: welcome, safety notice, quit-date setup, mascot selection, Home, check-in, craving toolkit, history/detail, optional account setup, and Settings/privacy.

## 8. iOS requirements

Proposed implementation: native Swift and SwiftUI, targeting iOS 17 and later. Confirm supported devices and deployment target before engineering begins. iPhone is required; iPad layouts, Apple Watch, widgets, and Android are deferred.

Use local persistence with iOS data protection and Keychain for tokens. Support offline reading and writing of check-ins and journal entries. Use local notifications for reminders; remote push is not required for MVP. Provide VoiceOver labels, logical focus order, sufficient contrast, large text layouts, non-color status indicators, and approximately 44-point or larger interactive targets.

Full iOS builds, Simulator tests, signing, and App Store submission require macOS with Xcode. A Linux cloud environment can support Cloudflare backend development and documentation but cannot complete native iOS validation. Apple Developer membership and signing configuration are required for distribution.

## 9. Cloudflare backend architecture

| Component | Responsibility |
| --- | --- |
| Cloudflare Workers | Versioned HTTPS JSON API, authentication validation, authorization, input validation, and rate limiting |
| Cloudflare D1 | Accounts, preferences, check-ins, journal entries, consent records, and synchronization metadata |
| Cloudflare Queues and scheduled Workers | Retryable deletion/export jobs and bounded cleanup tasks |
| Cloudflare R2 | Optional short-lived export artifacts; omit if streamed exports meet requirements |
| Workers secrets | Server-side credentials and signing material; never embed privileged tokens in the iOS app |

Use separate development, staging, and production resources. Manage schema migrations in version control and test them against a local database before remote deployment. Select service regions, retention, contractual controls, and data handling policies after privacy review; do not claim regulatory compliance solely because Cloudflare hosts the backend.

Sign in with Apple tokens must be verified server-side against Apple's public keys, expected issuer, audience, expiry, and nonce. Issue short-lived API sessions with revocable refresh credentials; store only hashed refresh tokens server-side. A client-supplied user ID is never authorization.

Proposed API:

| Method and path | Purpose |
| --- | --- |
| `POST /v1/auth/apple` | Exchange a verified Apple identity credential for a session |
| `POST /v1/auth/refresh` | Rotate refresh credentials |
| `POST /v1/auth/logout` | Revoke a session |
| `GET /v1/me` | Read account and synchronization state |
| `PATCH /v1/me/preferences` | Update quit date, mascot, and preferences |
| `PUT /v1/check-ins/{id}` | Idempotently create or update an owned check-in |
| `DELETE /v1/check-ins/{id}` | Create a deletion tombstone for synchronization |
| `GET /v1/sync?cursor=...` | Read incremental changes and tombstones |
| `POST /v1/exports` | Request an authenticated export |
| `DELETE /v1/me` | Revoke access and enqueue account deletion |
| `GET /health` | Return minimal service health without private information |

Journal notes may be part of check-ins in MVP; standalone journaling is deferred. Apply strict length limits and validation to notes and other fields. Return stable error codes and retry guidance without exposing implementation details.

## 10. Data and synchronization

Minimum entities:

- Account: internal ID, Apple subject, creation/deletion timestamps, consent version.
- Preferences: user ID, quit date, timezone, mascot choice, optional spending baseline, revision.
- Check-in: client-generated UUID, user ID, local date and timezone, optional drinking status, mood, craving intensity, optional triggers/note, revision, server modification time.
- Sync change/tombstone: owner, record ID, sequence/cursor, deletion marker.
- Session: hashed refresh token, owner, expiry, revocation state.

Use an offline outbox and idempotent writes. Server-assigned revisions support optimistic concurrency; reject stale updates with a conflict response and retain both versions until resolved. Server sequence cursors avoid reliance on device clocks. Deletion tombstones prevent deleted entries from reappearing on another device. Deduplicate daily check-ins by account and local date, with explicit handling when the user changes timezone.

Guest data remains local until explicit cloud-sync consent. Before linking to an existing account, explain the merge and resolve duplicate dates without discarding notes silently. Logging out must offer a clear choice about retaining local records and prevent a subsequent account from seeing another person's data.

## 11. Privacy and security

Treat alcohol-use records and journal notes as sensitive. Collect the minimum necessary information. Do not include journal text, drinking answers, tokens, or contact details in logs, analytics, crash reports, URLs, or push payloads. No advertising SDKs or sale of health-related data in MVP.

Require TLS, per-user authorization on every data operation, validated inputs, bounded request sizes, rate limits, secret rotation procedures, and audit events that exclude sensitive content. Verify cross-account isolation with automated tests. Store support contacts on-device by default, using a user-selected contact rather than requesting the whole address book.

Document actual encryption and key handling; do not claim end-to-end encryption unless implemented and independently verified. Define backup retention and deletion behavior before launch. Proposed target: active server data removed within 30 days of an account-deletion request, with backup expiry documented separately and confirmed against provider capabilities.

App Store privacy disclosures, an accessible privacy policy, and in-app account deletion must reflect actual behavior. Analytics consent and legal requirements require review for launch markets. Position the app for adults and select the App Store rating through Apple's current questionnaire.

## 12. Out of scope for MVP

AI counseling, clinical diagnosis, medication recommendations, withdrawal management, community chat, leaderboards, location tracking, HealthKit integration, paid subscriptions, and third-party advertising. These introduce additional evidence, moderation, privacy, or safety requirements and need separate decisions.

## 13. Validation and release criteria

- iOS unit tests cover calendar/timezone progress, savings estimates, streak behavior, offline outbox replay, and conflict resolution.
- iOS UI tests cover onboarding, optional mascot selection, check-ins, setback support, offline craving tools, export, and account deletion.
- Backend tests cover Apple token failures, session rotation/revocation, cross-account access denial, input limits, idempotency, incremental sync, and deletion retries.
- Integration tests use a staging Worker and D1 database to confirm save/read/edit/delete behavior and reconnection after offline edits.
- Accessibility review verifies VoiceOver, large text, contrast, reduced motion, and reachable controls on supported iPhones.
- Diverse usability participants validate mascot comfort and complete core tasks against the targets above.
- Qualified clinical reviewers approve withdrawal and crisis guidance; privacy/security review approves data handling and release disclosures.
- TestFlight beta confirms crash reporting is scrubbed, notification text is discreet, and data deletion/export behaves as documented.

Release only after required failures are resolved, production migrations and rollback procedures are rehearsed, and the App Store build passes review. No clinical outcome claims without appropriate evidence.

## 14. Delivery plan

1. Design: approve core flows, visual system, mascot concepts, safety content, and data policy.
2. Foundation: establish SwiftUI app, local storage, offline toolkit, Cloudflare development/staging environments, and CI.
3. Core MVP: implement onboarding, check-ins, progress, optional authentication, sync, reminders, export, and deletion.
4. Validation: complete functional, accessibility, clinical-content, security, and usability reviews; run TestFlight beta.
5. Launch: prepare production configuration, support documentation, privacy disclosures, App Store assets, and staged rollout.

Engineering estimates follow approved designs and architecture. Required external resources are a Cloudflare account, Apple Developer account, macOS/Xcode build capacity, product artwork, and clinical/privacy reviewers. Keep credentials in approved secret storage, never Git.

## 15. Open decisions and defaults

| Decision | Default for planning |
| --- | --- |
| Business model | Free MVP, no ads; revisit after user research |
| Launch language/region | English first; select launch markets before legal and resource localization |
| Account requirement | Optional; local guest experience first |
| Mascot presentation | Equal boy/girl choices, customization, and skip/reduced-mascot mode |
| Backend | Cloudflare Workers + D1; add Queues for asynchronous jobs and R2 only if needed |
| Client | Native iPhone app with SwiftUI, iOS 17+ |
| Product identity | Tommy is a working title pending review |

