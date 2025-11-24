# Complete Guide to Using SSH with Git

> Yes, I made AI generate this cause I'm to lazy to write it myself. I need to go through this and fact check all it wrote
still

This guide covers everything you need to use SSH for Git operations across Windows, macOS, and Linux, eliminating the need for git-credential-manager.

## Table of Contents

1. [Why Use SSH?](#why-use-ssh)
2. [Generating SSH Keys](#generating-ssh-keys)
3. [Adding SSH Keys to SSH Agent](#adding-ssh-keys-to-ssh-agent)
4. [Adding SSH Keys to GitHub](#adding-ssh-keys-to-github)
5. [Configuring Git to Use SSH](#configuring-git-to-use-ssh)
6. [SSH Commit Signing (Optional)](#ssh-commit-signing-optional)
7. [Troubleshooting](#troubleshooting)

## Why Use SSH?

Using SSH for Git operations provides several benefits:

- No need for git-credential-manager on any OS
- Same authentication method works consistently across Windows, macOS, and Linux
- More secure than HTTPS with tokens
- Can use the same key for authentication and commit signing
- Once set up, completely seamless experience

## Generating SSH Keys

### Check for Existing Keys

First, check if you already have SSH keys:

```bash
ls -la ~/.ssh
```

Look for files like `id_rsa.pub`, `id_ed25519.pub`, or `id_ecdsa.pub`. If you have these, you can skip key generation.

### Generate a New SSH Key

The recommended algorithm is Ed25519 (faster and more secure than RSA):

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

If your system doesn't support Ed25519, use RSA:

```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

When prompted:

1. **File location**: Press Enter to accept the default (`~/.ssh/id_ed25519`)
2. **Passphrase**: Enter a secure passphrase (recommended) or leave empty for no passphrase

### Understanding the Generated Files

Two files are created:

- `~/.ssh/id_ed25519` - Your private key (NEVER share this)
- `~/.ssh/id_ed25519.pub` - Your public key (this goes on GitHub)

## Adding SSH Keys to SSH Agent

The SSH agent manages your keys and passphrases so you don't have to enter them repeatedly.

### macOS

Start the SSH agent:

```bash
eval "$(ssh-agent -s)"
```

Check if `~/.ssh/config` exists, if not create it:

```bash
touch ~/.ssh/config
```

Edit `~/.ssh/config` and add:

```
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```

Add your key to the agent:

```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

**Note**: On macOS versions before Monterey, use `-K` instead of `--apple-use-keychain`.

### Linux

Start the SSH agent:

```bash
eval "$(ssh-agent -s)"
```

Add your key:

```bash
ssh-add ~/.ssh/id_ed25519
```

To make the agent start automatically, add to your `~/.bashrc` or `~/.zshrc`:

```bash
if [ -z "$SSH_AUTH_SOCK" ]; then
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi
```

### Windows

If using Git Bash or WSL, follow the Linux instructions above.

If using PowerShell:

```powershell
# Start the service
Start-Service ssh-agent

# Add your key
ssh-add $env:USERPROFILE\.ssh\id_ed25519
```

To start ssh-agent automatically, set the service to automatic:

```powershell
Get-Service ssh-agent | Set-Service -StartupType Automatic
```

## Adding SSH Keys to GitHub

### Copy Your Public Key

**macOS:**
```bash
pbcopy < ~/.ssh/id_ed25519.pub
```

**Linux (with xclip):**
```bash
xclip -selection clipboard < ~/.ssh/id_ed25519.pub
```

**Linux (without xclip):**
```bash
cat ~/.ssh/id_ed25519.pub
# Select and copy the output
```

**Windows (PowerShell):**
```powershell
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub | Set-Clipboard
```

**Windows (Git Bash):**
```bash
clip < ~/.ssh/id_ed25519.pub
```

### Add Key to GitHub

1. Go to GitHub.com and log in
2. Click your profile picture → **Settings**
3. Click **SSH and GPG keys** in the sidebar
4. Click **New SSH key**
5. Give it a descriptive title (e.g., "Work Laptop - macOS")
6. Select key type: **Authentication Key**
7. Paste your public key into the "Key" field
8. Click **Add SSH key**

### Test Your Connection

```bash
ssh -T git@github.com
```

You should see:

```
Hi username! You've successfully authenticated, but GitHub does not provide shell access.
```

## Configuring Git to Use SSH

### Converting Existing Repositories

Check your current remote URL:

```bash
git remote -v
```

If you see `https://github.com/...`, convert to SSH:

```bash
git remote set-url origin git@github.com:username/repo.git
```

### Cloning New Repositories

Always use the SSH URL when cloning:

```bash
git clone git@github.com:username/repo.git
```

**Don't use:**
```bash
git clone https://github.com/username/repo.git
```

### Finding SSH URLs on GitHub

On any GitHub repository page:

1. Click the green **Code** button
2. Select the **SSH** tab
3. Copy the URL that starts with `git@github.com:`

## SSH Commit Signing (Optional)

Using the same SSH key for commit signing adds "Verified" badges to your commits on GitHub.

### Configure Git for SSH Signing

```bash
# Tell Git to use SSH for signing
git config --global gpg.format ssh

# Specify your SSH key
git config --global user.signingkey ~/.ssh/id_ed25519.pub
```

### Enable Automatic Signing

Sign all commits automatically:

```bash
git config --global commit.gpgsign true
```

Sign all tags automatically:

```bash
git config --global tag.gpgsign true
```

### Add Signing Key to GitHub

1. Go to GitHub.com → **Settings** → **SSH and GPG keys**
2. Click **New SSH key**
3. Give it a title (e.g., "Signing Key - Work Laptop")
4. Select key type: **Signing Key**
5. Paste your public key (`~/.ssh/id_ed25519.pub`)
6. Click **Add SSH key**

**Important**: You need to add your key twice on GitHub - once as an authentication key and once as a signing key.

### Test Commit Signing

```bash
# Make a test commit
git commit --allow-empty -m "Test signed commit"

# Verify the signature
git log --show-signature -1
```

You should see "Good signature" in the output.

## Troubleshooting

### Permission Denied (publickey)

**Problem**: `git push` returns "Permission denied (publickey)"

**Solutions**:

1. Verify your SSH key is added to GitHub:
   ```bash
   ssh -T git@github.com
   ```

2. Check if ssh-agent is running:
   ```bash
   ssh-add -l
   ```

3. If no identities are listed, add your key:
   ```bash
   ssh-add ~/.ssh/id_ed25519
   ```

4. Verify you're using the SSH URL:
   ```bash
   git remote -v
   ```

### Could Not Open a Connection to Your Authentication Agent

**Problem**: `ssh-add` returns this error

**Solution**: Start the SSH agent first:

```bash
eval "$(ssh-agent -s)"
```

### Sign_and_send_pubkey: Signing Failed

**Problem**: Agent has no identities

**Solution**: Add your key to the agent:

```bash
ssh-add ~/.ssh/id_ed25519
```

### macOS Keychain Issues

**Problem**: macOS keeps asking for SSH passphrase after restart

**Solution**: Make sure your `~/.ssh/config` includes:

```
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```

Then add the key with keychain support:

```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

### Multiple SSH Keys

**Problem**: You need different keys for different services (GitHub, GitLab, work, personal)

**Solution**: Configure `~/.ssh/config`:

```
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_github

Host gitlab.com
  HostName gitlab.com
  User git
  IdentityFile ~/.ssh/id_ed25519_gitlab

Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
```

For the custom host, clone using:

```bash
git clone git@github-work:company/repo.git
```

### WSL-Specific Issues

**Problem**: SSH agent doesn't persist between WSL sessions

**Solution**: Use keychain (install via package manager):

```bash
# Ubuntu/Debian
sudo apt install keychain

# Add to ~/.bashrc or ~/.zshrc
eval $(keychain --eval --quiet id_ed25519)
```

## Quick Reference

### Essential Commands

```bash
# Generate key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Start agent
eval "$(ssh-agent -s)"

# Add key to agent
ssh-add ~/.ssh/id_ed25519

# Test GitHub connection
ssh -T git@github.com

# Convert remote to SSH
git remote set-url origin git@github.com:username/repo.git

# View current remote
git remote -v

# Configure SSH signing
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true
```

### SSH URL Format

```
git@github.com:username/repository.git
```

**Not**:
```
https://github.com/username/repository.git
```

## Benefits Summary

Once SSH is set up:

- Push/pull without entering credentials
- Works identically on Windows, macOS, and Linux
- No git-credential-manager needed
- Can use same key for commit signing
- More secure than HTTPS tokens
- Faster authentication

## Additional Resources

- [GitHub SSH Documentation](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [GitHub SSH Commit Signing](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification)
- [SSH Config File Documentation](https://man.openbsd.org/ssh_config)
