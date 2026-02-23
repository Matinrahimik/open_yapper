# Sign and Notarize Open Yapper for macOS

Follow these steps to sign the app so users won't see the malware warning.

---

## Step 0: Align Version and Tag

Before building, set the app version in `pubspec.yaml`:

```yaml
version: 1.0.1+1
```

- Use the same semantic version for your GitHub release tag: `v1.0.1`
- Keep `pubspec.yaml` and tag in sync for update checks.

---

## Step 1: Create Developer ID Certificate

You have Apple Development certs, but you need **Developer ID Application** for distribution:

1. Open **Xcode**
2. **Xcode → Settings** (or Preferences) → **Accounts**
3. Select your Apple ID → **Manage Certificates**
4. Click the **+** button at the bottom
5. Choose **Developer ID Application**
6. Click **Done** — the certificate is now in your Keychain

---

## Step 2: Create App-Specific Password

1. Go to https://appleid.apple.com
2. Sign in → **Sign-In and Security** → **App-Specific Passwords**
3. Click **+** to generate a new password
4. Name it "Open Yapper Notarization"
5. **Copy the password** (format: xxxx-xxxx-xxxx-xxxx) — you won't see it again

---

## Step 3: Get Your Team ID

1. Go to https://developer.apple.com/account
2. **Membership** → your **Team ID** is shown (10 characters, e.g. `BV2P33MF6N`)

---

## Step 4: Run the Sign & Notarize Script

Open Terminal and run:

```bash
cd /Users/matinrahimi/CursorProjects/open_yapper

# Set your credentials (replace with your actual values)
export APPLE_ID="matinrahimik@gmail.com"
export APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
export DEVELOPER_ID="Developer ID Application: Matin Rahimi (YOUR_TEAM_ID)"
export TEAM_ID="YOUR_TEAM_ID"

# Run the script
chmod +x scripts/sign-and-notarize-macos.sh
./scripts/sign-and-notarize-macos.sh
```

**Replace:**
- `xxxx-xxxx-xxxx-xxxx` with your App-Specific Password
- `YOUR_TEAM_ID` with your 10-character Team ID
- If your name differs in the certificate, use the exact name from Keychain Access → My Certificates

---

## Step 5: Upload to GitHub

1. The script creates:
   - `open_yapper.dmg` (stable/latest download URL)
   - `open_yapper-vX.Y.Z.dmg` (versioned release asset)
   - `open_yapper-vX.Y.Z.zip` (Sparkle/appcast archive)
2. Go to https://github.com/Matinrahimik/open_yapper/releases
3. Create/edit release with tag `vX.Y.Z`
4. Upload the signed assets from Step 1
5. Keep `open_yapper.dmg` as the stable asset for `releases/latest/download/open_yapper.dmg`
6. Save

---

## Step 6: Sparkle Appcast (Auto-Update Feed)

Sparkle uses an appcast XML feed (for example `appcast.xml`) referenced by `SUFeedURL` in `macos/Runner/Info.plist`.

Recommended flow:

1. Generate/update appcast from your release artifacts
2. Publish `appcast.xml` at a stable URL
3. Ensure each item version matches the Git tag and app version

If `appcast.xml` is missing or stale, in-app update checks can still detect versions via GitHub, but one-tap native install will not be reliable.

Done! New downloads will install without the malware warning.
