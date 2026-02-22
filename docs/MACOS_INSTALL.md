# Fixing the "App Could Be Malware" Warning on macOS

macOS Gatekeeper blocks apps that aren't signed by an Apple Developer. You have two options:

---

## Option 1: Quick Workaround (For Users Right Now)

**Right-click method:**
1. Download the DMG from the website
2. Open the DMG and drag Open Yapper to Applications
3. **Right-click** (or Control+click) the Open Yapper app
4. Click **Open** (not double-click)
5. Click **Open** in the dialog to confirm
6. The app will open and macOS will remember your choice

**System Settings method:**
1. Try to open the app (double-click)
2. When blocked, go to **System Settings → Privacy & Security**
3. Scroll down to see "Open Yapper was blocked..."
4. Click **Open Anyway**
5. Confirm in the dialog

---

## Option 2: Proper Fix (Code Sign + Notarize)

To remove the warning entirely, sign and notarize the app with Apple. This requires:

- **Apple Developer Program** ($99/year): https://developer.apple.com/programs/
- **Developer ID Application** certificate (create in Xcode)
- **App-Specific Password** (create at appleid.apple.com)

### Steps

1. **Create certificates** in Xcode:
   - Xcode → Settings → Accounts → Manage Certificates
   - Click + → Developer ID Application

2. **Create App-Specific Password**:
   - https://appleid.apple.com → Sign-In and Security → App-Specific Passwords

3. **Run the sign & notarize script**:
   ```bash
   export APPLE_ID="your@email.com"
   export APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
   export DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)"
   chmod +x scripts/sign-and-notarize-macos.sh
   ./scripts/sign-and-notarize-macos.sh
   ```

4. **Upload the new DMG** to GitHub Releases (replace the existing one)

After notarization, users won't see any security warnings.
