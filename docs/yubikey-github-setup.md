# YubiKey SSH Setup for GitHub (Signing & Authentication)

This guide covers setting up a YubiKey for SSH authentication and commit signing with GitHub, including support for multiple accounts (e.g., GitHub EMU and public GitHub).

## Prerequisites

- YubiKey 5 series (supports FIDO2/resident keys)
- OpenSSH 8.2+ on Windows/macOS/Linux
- Git 2.34+ (for SSH commit signing)

---

## Part 1: Generate Resident SSH Key on YubiKey

### On your local machine (DevBox/laptop):

```bash
# Generate a resident key (stored on YubiKey)
# The -O resident flag stores the key on the YubiKey
# The -O verify-required flag requires PIN + touch for each use
ssh-keygen -t ed25519-sk -O resident -O verify-required -C "yourname@yubikey"
```

This creates:
- `~/.ssh/id_ed25519_sk` - Key handle (references the key on YubiKey)
- `~/.ssh/id_ed25519_sk.pub` - Public key

### Load the key into SSH agent:

```bash
ssh-add ~/.ssh/id_ed25519_sk
```

### Verify it's loaded:

```bash
ssh-add -L | grep sk-ssh-ed25519
```

---

## Part 2: Add Key to GitHub

You need to add the same public key **twice** - once for auth, once for signing.

### Get your public key:

```bash
cat ~/.ssh/id_ed25519_sk.pub
```

Output looks like:
```
sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAI... yourname@yubikey
```

### Add to GitHub:

1. Go to https://github.com/settings/keys (or your EMU instance)

2. **For Authentication:**
   - Click "New SSH Key"
   - Title: `YubiKey Auth`
   - Key type: **Authentication Key**
   - Paste your public key
   - Click "Add SSH key"

3. **For Signing:**
   - Click "New SSH Key" again
   - Title: `YubiKey Signing`
   - Key type: **Signing Key**
   - Paste the same public key
   - Click "Add SSH key"

---

## Part 3: Configure Git for SSH Signing

### Save public key to a file (on remote machine if using VS Code Remote):

```bash
# Create the public key file
echo 'YOUR_PUBLIC_KEY_HERE' > ~/.ssh/yubikey_signing.pub
chmod 644 ~/.ssh/yubikey_signing.pub
```

### Configure git:

```bash
# Use SSH for signing (not GPG)
git config --global gpg.format ssh

# Point to your public key file
git config --global user.signingkey "$HOME/.ssh/yubikey_signing.pub"

# Enable auto-signing for commits and tags
git config --global commit.gpgsign true
git config --global tag.gpgsign true
```

### Set up local signature verification (optional but recommended):

```bash
# Create allowed signers file
echo "your.email@example.com $(cat ~/.ssh/yubikey_signing.pub)" > ~/.ssh/allowed_signers

# Tell git where to find it
git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
```

---

## Part 4: VS Code Remote SSH Agent Forwarding

For using YubiKey on a remote machine via VS Code:

### On your local machine:

1. **Enable VS Code setting:**
   ```json
   {
       "remote.SSH.enableAgentForwarding": true
   }
   ```

2. **Add to SSH config** (`~/.ssh/config` on Windows: `C:\Users\<you>\.ssh\config`):
   ```
   Host your-remote-host
       ForwardAgent yes
   ```

3. **Ensure SSH agent is running:**
   - Windows: `Set-Service ssh-agent -StartupType Automatic; Start-Service ssh-agent`
   - macOS/Linux: Should auto-start, or add to shell profile

4. **Ensure key is loaded in agent:**
   ```bash
   ssh-add ~/.ssh/id_ed25519_sk
   ssh-add -L  # Verify
   ```

### Test on remote:

```bash
# Should show your YubiKey key
ssh-add -L | grep sk-ssh-ed25519

# Should authenticate (touch YubiKey)
ssh -T git@github.com
```

---

## Part 5: Multiple GitHub Accounts (EMU + Public)

GitHub doesn't allow the same SSH key on multiple accounts. You need **separate keys** for each account.

### Generate Multiple Resident Keys on YubiKey

YubiKey can store multiple resident keys. Use different usernames to distinguish them:

```bash
# For public GitHub
ssh-keygen -t ed25519-sk -O resident -O verify-required \
    -O application=ssh:github.com \
    -C "yourname@github-public" \
    -f ~/.ssh/id_ed25519_sk_github

# For GitHub EMU
ssh-keygen -t ed25519-sk -O resident -O verify-required \
    -O application=ssh:github-emu \
    -C "yourname@github-emu" \
    -f ~/.ssh/id_ed25519_sk_github_emu
```

The `-O application=ssh:name` creates distinct resident keys on the YubiKey.

### SSH Config for Multiple Accounts

Edit `~/.ssh/config`:

```
# Public GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_sk_github
    IdentitiesOnly yes

# GitHub EMU (replace with your EMU hostname if different)
Host github-emu
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_sk_github_emu
    IdentitiesOnly yes
```

### Clone repos using the right host

```bash
# Public GitHub - use github.com as normal
git clone git@github.com:username/repo.git

# GitHub EMU - use the host alias
git clone git@github-emu:org/repo.git

# Or update existing repo remote
git remote set-url origin git@github-emu:org/repo.git
```

### Per-Directory Git Config (Recommended)

Use git's `includeIf` to auto-configure based on directory:

In `~/.gitconfig`:
```ini
[user]
    name = Your Name
    email = personal@email.com
    signingkey = ~/.ssh/id_ed25519_sk_github.pub

[includeIf "gitdir:~/work/"]
    path = ~/.gitconfig-work
```

In `~/.gitconfig-work`:
```ini
[user]
    email = you@company.com
    signingkey = ~/.ssh/id_ed25519_sk_github_emu.pub
```

### Add Each Key to Respective GitHub Account

1. **Public GitHub** (github.com/settings/keys):
   - Add `~/.ssh/id_ed25519_sk_github.pub` as Auth + Signing key

2. **GitHub EMU** (your-emu-instance/settings/keys):
   - Add `~/.ssh/id_ed25519_sk_github_emu.pub` as Auth + Signing key

---

## Part 6: Local Devcontainers

VS Code automatically forwards your SSH agent into local devcontainers, so YubiKey signing can work.

### Test if agent forwarding works:

In a devcontainer terminal:
```bash
ssh-add -L  # Should show your YubiKey key
ssh -T git@github.com  # Should authenticate (touch YubiKey)
```

### If agent forwarding doesn't work:

Add to your `devcontainer.json`:

```json
{
  "remoteEnv": {
    "SSH_AUTH_SOCK": "${localEnv:SSH_AUTH_SOCK}"
  }
}
```

### Mount SSH keys for signing:

The signing key file needs to be available in the container. Add to `devcontainer.json`:

```json
{
  "mounts": [
    "source=${localEnv:HOME}/.ssh,target=/home/vscode/.ssh,type=bind,readonly"
  ]
}
```

### Configure git signing in container:

Add a `postCreateCommand` to set up git:

```json
{
  "postCreateCommand": "git config --global gpg.format ssh && git config --global user.signingkey ~/.ssh/yubikey_signing.pub && git config --global commit.gpgsign true && git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers"
}
```

### Complete devcontainer.json example:

```json
{
  "name": "Dev Container with YubiKey Signing",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  
  // Mount SSH keys (read-only for security)
  "mounts": [
    "source=${localEnv:HOME}/.ssh,target=/home/vscode/.ssh,type=bind,readonly"
  ],
  
  // Ensure agent socket is available
  "remoteEnv": {
    "SSH_AUTH_SOCK": "${localEnv:SSH_AUTH_SOCK}"
  },
  
  // Configure git signing
  "postCreateCommand": "git config --global gpg.format ssh && git config --global user.signingkey ~/.ssh/yubikey_signing.pub && git config --global commit.gpgsign true && git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers"
}
```

---

## Part 7: GitHub Codespaces

Codespaces handles authentication differently and **does not support SSH agent forwarding** for YubiKeys.

### Authentication in Codespaces
✅ **Automatic** - Codespaces has built-in access to your GitHub repos via the GitHub token. No SSH key needed for clone/push.

### Commit Signing Options

#### Option A: GitHub's Built-in Signing (Recommended)

GitHub can automatically sign commits made in Codespaces:

1. Go to **github.com/settings/codespaces**
2. Enable **"GPG verification"**
3. Commits will show as "Verified" using GitHub's key

This is the simplest approach. The signature is from GitHub, not your YubiKey.

#### Option B: GPG Key on YubiKey (Advanced)

If your YubiKey has GPG keys (separate from SSH), you can use GPG agent forwarding:

1. Set up GPG on your local machine with YubiKey
2. In github.com/settings/codespaces, enable **"GPG verification"** → Select your GPG key
3. GitHub forwards the GPG agent to the Codespace

This requires:
- GPG key on YubiKey (in addition to SSH key)
- GPG agent running locally
- More complex setup

#### Option C: Use GitHub CLI SSH (Experimental)

Connect to Codespaces via CLI with SSH:

```bash
gh codespace ssh
```

This may support agent forwarding, but behavior varies.

### Summary Table

| Environment | SSH Agent Forwarding | Commit Signing |
|-------------|---------------------|----------------|
| Local machine | ✅ Native | ✅ YubiKey SSH signing |
| VS Code Remote SSH | ✅ With `ForwardAgent yes` | ✅ YubiKey SSH signing |
| Local devcontainers | ✅ Auto-forwarded by VS Code | ✅ YubiKey SSH signing |
| GitHub Codespaces | ❌ Not supported | ⚠️ Use GitHub's built-in or GPG |

---

## Quick Reference

### Test Authentication:
```bash
ssh -T git@github.com
```

### Test Signing:
```bash
git commit --allow-empty -S -m "Test signed commit"
git log --show-signature -1
```

### Disable signing for one commit:
```bash
git commit --no-gpg-sign -m "Unsigned commit"
```

### View git signing config:
```bash
git config --global --get gpg.format
git config --global --get user.signingkey
git config --global --get commit.gpgsign
```

### Export resident key from YubiKey (if needed on new machine):
```bash
ssh-keygen -K  # Downloads resident keys from YubiKey
```

---

## Troubleshooting

### "Could not open a connection to your authentication agent"
- SSH agent isn't running or `SSH_AUTH_SOCK` isn't set
- Fix: Start the agent and add your key

### "No such file or directory" when signing
- Git can't find the signing key file
- Fix: Use full path in `user.signingkey`, not `~`

### YubiKey not detected
- Ensure YubiKey is plugged in
- Try `ssh-add -L` to see if agent sees it
- On Windows, you may need to use Git Bash or install OpenSSH 8.2+

### Agent forwarding not working in VS Code
- Check `remote.SSH.enableAgentForwarding` is `true`
- Check `ForwardAgent yes` is in SSH config
- Some VS Code extensions (like Wavespaces) may override SSH config
- Test with plain `ssh -A hostname` to verify it works outside VS Code

### Windows keeps showing YubiKey/Windows Hello popup
This is Windows Hello detecting your YubiKey for Windows sign-in, not SSH.

**To reduce popups:**
1. Open **Settings** → **Accounts** → **Sign-in options**
2. Under **Security Key**, remove any registered credentials if you don't use it for Windows login
3. Or in **YubiKey Manager** → **FIDO2** → manage credentials

The popup doesn't affect SSH operations - it's just Windows being eager.

### "Key is already in use" on GitHub
GitHub doesn't allow the same key on multiple accounts. Generate separate keys:
- Use `-O application=ssh:github.com` for public GitHub
- Use `-O application=ssh:github-emu` for EMU
- See "Part 5: Multiple GitHub Accounts" section

### Wrong key being used for commits
Check which key git is using:
```bash
git config --get user.signingkey
```
Use `includeIf` in `~/.gitconfig` for per-directory configs.
