# Stokli

Stokli is a Flutter equipment borrowing and return tracking system. The mobile app can use the PHP API and MySQL database running on XAMPP, with SQLite for offline work. The Flutter web app can connect to the same API; the original Figma Make React preview remains available at the project root.

## Web app

The Flutter Web app is published at <https://winterbanana.github.io/Stokli_Finals/>. It has no built-in demo accounts; connect it to a configured Stokli API and sign in with an account provisioned in MySQL. The browser does not connect directly to MySQL.

GitHub Pages builds and deploys the app from [`mobile/`](./mobile/) using the workflow in [`.github/workflows/deploy-web.yml`](./.github/workflows/deploy-web.yml). If Pages has not been enabled for the repository, select **Settings → Pages → GitHub Actions**.

## First run on Windows/XAMPP

1. Keep this project inside `C:\xampp\htdocs\Stokli BMC` (or update the XAMPP path in `launch_stokli.bat`).
2. Import [`database/stokli_bmc.sql`](./database/stokli_bmc.sql) in phpMyAdmin, or run [`launch_stokli.bat`](./launch_stokli.bat). The launcher starts MySQL and Apache and imports the file only when the `stokli_bmc` database does not exist.
3. In VS Code, open [`Stokli BMC.code-workspace`](./Stokli%20BMC.code-workspace). It keeps the complete repository visible while setting new integrated terminals and Flutter tasks to the authoritative `mobile/` project root. Select **Stokli BMC (Flutter)** in Run and Debug, or run **Flutter: run** from **Terminal → Run Task**. The workspace also supports the `launch_stokli.bat` launcher with an Android emulator running; it starts `flutter run` after the API is ready.
4. For a physical phone, build/run with the host API URL supplied privately at build time, for example `flutter run --dart-define=STOKLI_API_BASE_URL=http://192.168.1.10/Stokli%20BMC/api/index.php`. Keep the phone and host on the same Wi-Fi and allow Apache through Windows Firewall on a private network if asked.

XAMPP's default MySQL setup is expected to use `root` without a password. If your local credentials differ, set `STOKLI_DB_HOST`, `STOKLI_DB_PORT`, `STOKLI_DB_NAME`, `STOKLI_DB_USER`, and `STOKLI_DB_PASSWORD` in the environment used by Apache; the defaults are in [`api/config.php`](./api/config.php).

The SQL file seeds only the initial equipment catalogue and creates no user accounts. There is no default administrator; provision real accounts with unique credentials before signing in. Self-service registration is disabled.

## Flutter commands

`mobile/` is the only Flutter project root. When using the configured VS Code workspace, new integrated terminals and the Flutter tasks already start there; no directory change is needed. You can run **Flutter: pub get**, **Flutter: analyze**, **Flutter: test**, and **Flutter: run** through **Terminal → Run Task**, or press F5 with **Stokli BMC (Flutter)** selected. From an external terminal, first open `mobile/` as the working directory.

For the local defense setup, start XAMPP MySQL and Apache, then run the web client with the local API endpoint explicitly configured:

```powershell
cd "C:\xampp\htdocs\Stokli BMC\mobile"
flutter pub get
flutter run -d chrome --dart-define=STOKLI_API_BASE_URL=http://localhost/Stokli%20BMC/api/index.php
```

The browser connects to the PHP API; it does not connect directly to MySQL. The API permits browser CORS requests only from localhost/127.0.0.1 origins. To test from a different device, use a reachable host IP in `STOKLI_API_BASE_URL` and configure the API CORS allowlist for that exact origin before use. Chrome must be launched with the API endpoint configured to use the MySQL-backed system. No sample user accounts or borrowing records are seeded.

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

Build an Android release package with `flutter build apk --release`.
The prebuilt architecture-specific APKs are in `mobile/build/app/outputs/flutter-apk/`; use `app-arm64-v8a-release.apk` for most current Android phones. To regenerate them, run `flutter build apk --release --split-per-abi`.

## Mobile app and local server

The phone app does not run XAMPP on the phone. XAMPP must remain running on the Windows host, and the phone must be able to reach that host over the network. The API endpoint accepts local HTTP for development; do not expose it to a public network. For production, use HTTPS, strong credentials, and a properly secured MySQL account.

Student users can browse/scan equipment, submit borrowing requests, report a return with an optional photo, review penalties, and submit payment records for staff verification. Administrator accounts can review borrowing and return requests, adjust inventory, manage missing/damaged exceptions, verify payments, view account records, and inspect the audit log. Payment submissions are records for staff verification; the app does not charge GCash, Maya, or another wallet.

The sign-in form does not accept a client-selected role; the PHP API derives the role from the matched account record. Self-service registration is disabled, so accounts must be provisioned by an administrator. The server only accepts new borrowing requests from 08:00 through 18:59 Philippine time; this check also applies to requests synchronized from an offline device.

Both roles have a dedicated **Settings** page. Light, dark, and system appearance preferences are saved separately per account and apply app-wide. Users can edit permitted profile fields, change a password, and upload/remove a profile photo. In browser offline mode, changes remain in local storage until they can sync to MySQL. Administrators can view student account history and edit permitted student fields/status from **Accounts**. Notification categories are saved locally per account, but push/scheduled notification delivery is not configured. API endpoint configuration remains internal to the app build; there is no in-app server URL/test control.

**FAQ & Help Support** is bundled in the app and works offline. Its chat-style helper retrieves role-appropriate answers from the local Stokli guide only; it does not call an external AI provider or access live personal, borrowing, payment, or inventory records. The current schema does not provide an administrator password-reset workflow.

## Inventory browsing

Student and administrator inventory screens use the same MySQL equipment catalogue online and SQLite's cached copy offline. Inventory is requested in 30-record pages (up to 100 per API request), with server-side search across equipment ID/code, name, brand, model, category, serial number, and status. Use **Load more** to reach later records; changing search/category/status filters searches the complete matching inventory. Each fetched page is cached to SQLite for offline browsing; pages not yet fetched remain on the central server. The list loads compact metadata and small image decodes; tap an item for full details, and administrators can open its latest borrowing, return, and exception history there. Retired and otherwise non-borrowable equipment remains visible, while the student borrow action is disabled when current stock/status prohibits a request.

The API applies versioned schema migrations for older databases, including profile email/photo/version fields and inventory/search/history indexes. A migration removes the known legacy demo accounts and their dependent sample records; other user, equipment, and transaction data is retained. The migration runs when the API is first used after deployment; importing the SQL file is not a substitute for keeping a database backup.

## Offline mode and synchronization

The app persists cached server data and read snapshots in SQLite. Once an account has been cached on the device, borrowing, approvals, returns, payment records/reviews, supported inventory actions, and profile/photo updates can continue offline. Those writes are kept in a per-account outbox and shown as waiting to sync. When a previously connected app detects that XAMPP is reachable again, it restores its saved server session and attempts to replay queued operations; use **Sync** and re-authenticate with the same account if the session expired or an operation needs attention. Failed operations remain on-device with an error message. Requests created offline cannot appear in an administrator's separate device until synchronized, and the server still enforces the 08:00–18:59 Philippine borrowing window when the request is replayed. Profile changes use an expected server version; a conflict is reported and the queued edit is retained instead of silently overwriting newer data. Server operations carry idempotency keys, so retrying a response-lost operation does not create a second record. Account registration and password changes require a live server connection; passwords are not queued for offline sync. SQLite remains device-local and should not be treated as a backup; protect devices that contain cached personal data.
