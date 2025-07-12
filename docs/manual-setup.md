# Manual Setup Steps

Some tools and configurations require manual setup after running the main script.

## 🔐 Authentication & Credentials

### Claude CLI
```bash
claude setup-token
```
Follow the prompts to authenticate with your Anthropic account.

### Git Configuration
Update your personal information in `~/.gitconfig`:
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

## 🛠️ Application Configuration

### Visual Studio Code
1. Install extensions from the list:
   ```bash
   cat vscode/extensions.txt | xargs -L 1 code --install-extension
   ```
2. Import settings from `vscode/settings.json`
3. Configure themes and preferences as needed

### Terminal (Warp)
- Import color schemes and themes
- Configure AI features and shortcuts
- Set up custom prompts

### Browser Extensions
Install common development extensions:
- React Developer Tools
- Vue.js devtools
- Redux DevTools
- Web Developer
- JSON Formatter
- Wappalyzer

## 🔧 System Preferences

### Security & Privacy
- Enable FileVault disk encryption
- Configure Firewall settings
- Review Location Services

### Trackpad & Mouse
- Configure scroll direction
- Set up gestures
- Adjust tracking speed

### Dock & Menu Bar
- Remove unused applications from Dock
- Configure menu bar items
- Set up Spotlight preferences

## 📱 App Store Applications

These applications need to be installed manually from the App Store:
- Xcode (if not already installed)
- Pages, Numbers, Keynote (if needed)
- Any other App Store exclusives

## 🌐 Additional Tools

### Optional Development Tools
Consider installing these based on your workflow:
- Docker Desktop (GUI for Docker)
- Postman or Insomnia (API testing)
- TablePlus (Database client)
- Sequel Pro (MySQL client)
- MongoDB Compass (MongoDB GUI)

### Browser Setup
Configure your preferred browsers:
1. **Chrome**: Sign in to sync settings and extensions
2. **Firefox**: Configure privacy settings
3. **Safari**: Set up iCloud sync
4. **Brave**: Configure shields and rewards

## 🔄 Sync Settings

### iCloud
- Enable iCloud sync for desired apps
- Configure iCloud Drive
- Set up Keychain sync

### Backup Strategy
- Configure Time Machine
- Set up cloud backup (Backblaze, etc.)
- Export important configurations

## 📋 Verification Checklist

After completing manual setup:

- [ ] Claude CLI authenticated and working
- [ ] Git configured with your credentials
- [ ] VS Code extensions installed and configured
- [ ] Terminal customized to preferences
- [ ] Browser extensions installed
- [ ] System preferences configured
- [ ] Backup strategy in place
- [ ] All development tools tested

## 🚨 Troubleshooting

If you encounter issues:
1. Check the [troubleshooting guide](troubleshooting.md)
2. Verify Homebrew installation: `brew doctor`
3. Check shell configuration: `echo $SHELL`
4. Restart terminal and try again
