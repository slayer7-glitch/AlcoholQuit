# Tommy

A native iPhone wellness companion and a Cloudflare Workers API, organized by feature. Product requirements are in [PRD.md](PRD.md).

## Project layout

```text
ios/
  project.yml                     # XcodeGen project definition
  Tommy/
    App/                          # Application entry point and tab navigation
    Features/
      Authentication/             # Apple sign-in, Keychain sessions, cloud requests
      Onboarding/                 # Welcome, safety acknowledgment, companion selection
      Home/                       # Daily dashboard
      CheckIn/                    # Daily check-in creation and editing
      CravingSupport/             # Offline grounding and pause timer
      Progress/                   # History and recorded alcohol-free days
      Settings/                   # Preferences, export, local erasure
      Safety/                     # Offline safety guidance
    Shared/
      Components/                 # Reusable cards and companion presentation
      Models/                     # Shared domain types
      Services/                   # Device persistence and pending check-in sync
backend/
  src/
    features/
      authentication/             # Apple token verification and API sessions
      check-ins/                  # Validated, revisioned writes and deletions
      settings/                   # Preferences and account deletion
      sync/                       # Account-scoped change feed
    shared/                       # HTTP contracts and validation helpers
  migrations/                     # D1 schema
  tests/                          # API tests against real SQLite
```

Keep page-specific views, models, and services inside their feature directory. Promote code to `Shared` only when multiple features use it. Use the spelling `Authentication` consistently in code.

## Current implementation

The iOS source implements local onboarding, original boy/girl vector superheroes and a no-mascot choice, daily check-ins, editing history, progress, offline craving tools, preferences, JSON export, and local erasure. Expanded mascot customization is still needed. No account is required.

The backend implements Apple identity-token verification, hashed one-hour bearer sessions, logout, rate limiting, identity-token replay protection, preferences, revisioned check-in writes, deletion tombstones, cursor pagination, and account deletion. The iOS client supports optional Apple sign-in, Keychain sessions, a persistent pending check-in set, foreground/manual synchronization, and cloud account deletion. Set `API_BASE_URL` in Xcode to your deployed HTTPS Worker origin to enable it. Conflicting records are retained and reported rather than silently overwritten; an in-app conflict resolution interface is still needed. Users must sign in again after the one-hour session expires; refresh-token rotation is deferred. Preferences currently use last-write-wins on the backend and are not synchronized by the iOS client.

## iOS development (macOS required)

1. Install Xcode with iOS 17+ SDK and XcodeGen (`brew install xcodegen`).
2. Run `cd ios && xcodegen generate`.
3. Open `Tommy.xcodeproj`, select the Tommy scheme and an iPhone Simulator, then Run.
4. For a device build, choose your own unique bundle identifier and signing team in Xcode. Enable Sign in with Apple for the identifier in your Apple Developer account and match it with the backend's `APPLE_CLIENT_ID`. Set the app build setting `API_BASE_URL` to your HTTPS Worker origin. Leaving it blank keeps the app local-only.

Example build check on a Mac:

```sh
cd ios
xcodegen generate
xcodebuild -project Tommy.xcodeproj -scheme Tommy -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

Native compilation and UI behavior have not been verified in this Linux environment. No generated Xcode project or signing credentials are committed.

## Backend development

Use Node.js 24 (tests use its SQLite module).

```sh
cd backend
npm ci
npm run typecheck
npm test
npm run db:migrate:local
npm run dev
```

Check readiness with `curl http://localhost:8787/health`. Private endpoints require a real session. Tests seed hashed sessions in an isolated in-memory database; there is no development authentication bypass in the Worker.

### Cloudflare deployment

Create a D1 database with `npx wrangler d1 create alcoholquit`, replace the placeholder `database_id` in `wrangler.jsonc`, and set the actual Apple application identifier. Use separate configurations/databases for staging and production. Authenticate through your own Cloudflare tooling; keep credentials out of Git.

```sh
npm exec wrangler d1 migrations apply alcoholquit -- --remote
npm run deploy
```

For Apple sign-in, the native client must generate a cryptographically random raw nonce and send its SHA-256 digest to Apple. Send the original raw nonce and returned identity token to `POST /v1/auth/apple`. Use the returned bearer token in the Authorization header. The backend validates signature, issuer, audience, age, expiry, and nonce. Complete Apple's capability setup and validate the real exchange on a signed device before release. Local tests verify cryptographic validation against test signing keys; they do not prove your Apple account configuration.

## API

All request bodies use JSON. Private routes require `Authorization: Bearer <session>`.

- `GET /health`
- `POST /v1/auth/apple` — `{identityToken, nonce}`
- `POST /v1/auth/logout`
- `GET /v1/me`
- `PATCH /v1/me/preferences` — `{companion, reason, quitDate}`
- `PUT /v1/check-ins/:uuid` — `{localDate:"YYYY-MM-DD", mood, drinkingStatus, note, revision:0}` for creation; use returned revision for edits
- `DELETE /v1/check-ins/:uuid` — `{revision}`
- `GET /v1/sync?cursor=0` — up to 100 changes, next cursor, and `hasMore`
- `DELETE /v1/me` — deletes active account data and revokes sessions; provider backups follow the separately configured retention policy

Mood values: `Great`, `Okay`, `Low`, `Overwhelmed`. Drinking status: `No`, `Yes`, `Prefer not to say`. An identical retry of the most recent write is accepted; stale conflicting edits return 409. A different record for an occupied calendar date also returns 409. Client account IDs are never accepted as authorization.

## Remaining before a public release

- Compile and exercise the app with Xcode. Run the included native persistence/progress tests and add calendar/UI coverage.
- Validate the implemented Apple sign-in and foreground/manual sync on real devices. Add conflict resolution UI, robust guest merge, preference sync, and cross-device/native integration tests.
- Add refresh-token rotation, operational monitoring, and a retention policy for change history. Rate limiting is configured at 60 requests per minute per source IP; tune for deployment. Expired sessions and token replay records are pruned during sign-in.
- Implement cloud export, spending estimates, localization, support-contact UI, and expanded mascot appearance options. Daily local reminders and vector mascots are included.
- Complete accessibility/usability testing, clinical review of safety content, privacy/legal review, backup/deletion policy, and TestFlight validation.

Safety content is draft wellness guidance and requires qualified clinical review. This project is a development foundation, not a release-ready medical product. No production resources are created by cloning or running tests.

## Validation in this workspace

Backend TypeScript checking and 12 API tests passed, covering real SQLite migrations, signed identity-token validation, replay rejection, rate limiting, account isolation, revisions, retry safety, deletion, and preferences. Local Wrangler migration and HTTP smoke checks were also run. Four native persistence/progress tests and a macOS CI job are included but have not run in this Linux workspace. Check GitHub Actions for the first native build result after pushing.

The product and Xcode project are named Tommy. Existing bundle identifiers, Keychain service identifiers, local storage paths, and the D1 database name are retained so renaming does not disconnect existing data or provisioning. The GitHub repository remains `slayer7-glitch/AlcoholQuit`.

## View iPhone screenshots from Windows

No local Xcode or Apple Developer membership is needed for simulator screenshots. GitHub Actions runs Xcode on a hosted Mac.

1. Open [Actions → Validate](https://github.com/slayer7-glitch/AlcoholQuit/actions/workflows/ci.yml) while signed into GitHub.
2. Select the newest run for `main`. Screenshots run automatically after pushes. To request a fresh set, choose **Run workflow**, select `main`, and confirm **Run workflow**.
3. Wait for the `ios` job to finish. The initial build can take several minutes.
4. Open the run's summary and scroll to **Artifacts**. Download **Tommy-iPhone-Screenshots**.
5. Extract the ZIP in Windows and open its PNG files in Photos. Subfolders and the exported manifest associate attachments with the screenshot test. The files cover onboarding, Home, check-in, craving support, progress, settings, authentication, and safety.

The screenshots show the actual SwiftUI app in an iPhone Simulator with fictional sample data. Each screen starts with isolated temporary storage, and screenshot routing is compiled only into debug simulator builds. No Apple sign-in or backend credentials are needed. These are static progress previews rather than an interactive Windows app. The screenshot test waits for each screen to load; it does not validate every control or layout.

If screenshots are missing, open the `ios` job and inspect the failed step. A compile failure prevents screenshot generation. **Tommy-iOS-TestResults**, when present, contains diagnostic Xcode results. Screenshot artifacts expire after 14 days; run the workflow again for a fresh download. GitHub-hosted macOS runner availability and billing depend on your repository/account settings. Enable Actions if GitHub prompts you.

This workflow has not been executed locally because this workspace does not include macOS/Xcode. The first GitHub run must confirm native compilation and screenshot capture.
