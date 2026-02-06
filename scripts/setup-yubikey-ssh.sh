#!/bin/bash
# YubiKey SSH Setup Script for GitHub
# This script configures git for SSH signing and authentication using a YubiKey
# Supports multiple GitHub accounts (e.g., public + EMU)
#
# Usage: 
#   ./setup-yubikey-ssh.sh                          # Configure with existing key
#   ./setup-yubikey-ssh.sh --generate-key           # Generate new key
#   ./setup-yubikey-ssh.sh --generate-key --account github-emu  # For EMU account

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
GENERATE_KEY=false
EMAIL=""
ACCOUNT_NAME=""
KEY_COMMENT="yubikey"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --generate-key)
            GENERATE_KEY=true
            shift
            ;;
        --email)
            EMAIL="$2"
            shift 2
            ;;
        --account)
            ACCOUNT_NAME="$2"
            shift 2
            ;;
        --comment)
            KEY_COMMENT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --generate-key      Generate a new resident key on YubiKey"
            echo "  --email EMAIL       Email address for git config and allowed_signers"
            echo "  --account NAME      Account name (e.g., 'github-emu' for EMU, empty for public)"
            echo "                      Creates separate keys for multiple GitHub accounts"
            echo "  --comment NAME      Comment for the SSH key (default: yubikey)"
            echo "  -h, --help          Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                    # Setup with existing key in agent"
            echo "  $0 --generate-key                     # Generate key for public GitHub"
            echo "  $0 --generate-key --account github-emu  # Generate key for EMU"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Determine key file names based on account
if [ -n "$ACCOUNT_NAME" ]; then
    KEY_FILE="id_ed25519_sk_${ACCOUNT_NAME}"
    KEY_COMMENT="${KEY_COMMENT}-${ACCOUNT_NAME}"
    APP_NAME="ssh:${ACCOUNT_NAME}"
else
    KEY_FILE="id_ed25519_sk_github"
    APP_NAME="ssh:github.com"
fi

echo -e "${GREEN}=== YubiKey SSH Setup for GitHub ===${NC}"
if [ -n "$ACCOUNT_NAME" ]; then
    echo -e "Account: ${YELLOW}${ACCOUNT_NAME}${NC}"
fi
echo ""

# Step 1: Generate key if requested (only on local machine, not remote)
if [ "$GENERATE_KEY" = true ]; then
    echo -e "${YELLOW}Step 1: Generating resident SSH key on YubiKey...${NC}"
    echo "Application: $APP_NAME"
    echo "You will need to touch your YubiKey and enter your PIN."
    echo ""
    
    ssh-keygen -t ed25519-sk -O resident -O verify-required \
        -O "application=$APP_NAME" \
        -C "${KEY_COMMENT}" \
        -f "$HOME/.ssh/${KEY_FILE}"
    
    echo ""
    echo -e "${GREEN}Key generated successfully!${NC}"
    echo "  Private key handle: ~/.ssh/${KEY_FILE}"
    echo "  Public key: ~/.ssh/${KEY_FILE}.pub"
    echo ""
    
    # Add to agent
    echo "Adding key to SSH agent..."
    ssh-add "$HOME/.ssh/${KEY_FILE}"
    
    # Use the just-generated key
    YUBIKEY_PUBKEY=$(cat "$HOME/.ssh/${KEY_FILE}.pub")
else
    # Step 2: Check for YubiKey SSH key in agent
    echo -e "${YELLOW}Checking for YubiKey SSH key in agent...${NC}"
    
    if [ -n "$ACCOUNT_NAME" ]; then
        # Look for specific account key
        YUBIKEY_PUBKEY=$(ssh-add -L 2>/dev/null | grep "sk-ssh-ed25519" | grep "$ACCOUNT_NAME" | head -1 || true)
    fi
    
    if [ -z "$YUBIKEY_PUBKEY" ]; then
        # Fall back to any sk key
        YUBIKEY_PUBKEY=$(ssh-add -L 2>/dev/null | grep "sk-ssh-ed25519" | head -1 || true)
    fi
    
    if [ -z "$YUBIKEY_PUBKEY" ]; then
        echo -e "${RED}Error: No YubiKey SSH key found in agent.${NC}"
        echo ""
        echo "Make sure:"
        echo "  1. Your YubiKey is plugged in"
        echo "  2. You have a resident key on it (run with --generate-key to create one)"
        echo "  3. The key is loaded in the SSH agent (ssh-add ~/.ssh/id_ed25519_sk*)"
        echo "  4. If remote, SSH agent forwarding is enabled"
        exit 1
    fi
fi

echo -e "${GREEN}Found YubiKey SSH key:${NC}"
echo "$YUBIKEY_PUBKEY"
echo ""

# Step 3: Get email if not provided
if [ -z "$EMAIL" ]; then
    # Try to get from git config
    EMAIL=$(git config --global user.email 2>/dev/null || true)
    
    if [ -z "$EMAIL" ]; then
        echo -n "Enter your email address (for git and allowed_signers): "
        read EMAIL
    else
        echo "Using email from git config: $EMAIL"
        echo -n "Press Enter to confirm or type a different email: "
        read NEW_EMAIL
        if [ -n "$NEW_EMAIL" ]; then
            EMAIL="$NEW_EMAIL"
        fi
    fi
fi

# Step 4: Save public key to file
SIGNING_KEY_FILE="yubikey_signing"
if [ -n "$ACCOUNT_NAME" ]; then
    SIGNING_KEY_FILE="yubikey_signing_${ACCOUNT_NAME}"
fi

echo -e "${YELLOW}Saving public key to ~/.ssh/${SIGNING_KEY_FILE}.pub...${NC}"
echo "$YUBIKEY_PUBKEY" > "$HOME/.ssh/${SIGNING_KEY_FILE}.pub"
chmod 644 "$HOME/.ssh/${SIGNING_KEY_FILE}.pub"
echo -e "${GREEN}Done.${NC}"
echo ""

# Step 5: Configure git for SSH signing
echo -e "${YELLOW}Configuring git for SSH signing...${NC}"

git config --global gpg.format ssh
git config --global user.signingkey "$HOME/.ssh/${SIGNING_KEY_FILE}.pub"
git config --global commit.gpgsign true
git config --global tag.gpgsign true

echo -e "${GREEN}Git signing configured.${NC}"
echo ""

# Step 6: Create/update allowed_signers file
echo -e "${YELLOW}Updating allowed_signers file for local verification...${NC}"

ALLOWED_SIGNERS_FILE="$HOME/.ssh/allowed_signers"
SIGNER_ENTRY="$EMAIL $YUBIKEY_PUBKEY"

if [ -f "$ALLOWED_SIGNERS_FILE" ]; then
    # Check if this email already has an entry and update it, or append
    if grep -q "^$EMAIL " "$ALLOWED_SIGNERS_FILE"; then
        # Update existing entry
        sed -i "s|^$EMAIL .*|$SIGNER_ENTRY|" "$ALLOWED_SIGNERS_FILE"
        echo "Updated existing entry for $EMAIL"
    else
        # Append new entry
        echo "$SIGNER_ENTRY" >> "$ALLOWED_SIGNERS_FILE"
        echo "Added new entry for $EMAIL"
    fi
else
    echo "$SIGNER_ENTRY" > "$ALLOWED_SIGNERS_FILE"
    echo "Created new allowed_signers file"
fi

chmod 644 "$ALLOWED_SIGNERS_FILE"
git config --global gpg.ssh.allowedSignersFile "$ALLOWED_SIGNERS_FILE"
echo -e "${GREEN}Done.${NC}"
echo ""

# Step 7: Test GitHub connection
echo -e "${YELLOW}Testing GitHub SSH connection...${NC}"
echo "(Touch your YubiKey when prompted)"
echo ""

if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo -e "${GREEN}GitHub authentication successful!${NC}"
else
    echo -e "${YELLOW}GitHub may not have this key yet.${NC}"
    echo ""
    echo "Add this key to GitHub:"
    echo "  1. Go to https://github.com/settings/ssh/new"
    echo "  2. Add as 'Authentication Key'"
    echo "  3. Add again as 'Signing Key'"
    echo ""
    echo "Public key to copy:"
    echo ""
    echo "$YUBIKEY_PUBKEY"
fi
echo ""

# Step 8: Test signing
echo -e "${YELLOW}Testing commit signing...${NC}"
echo "(Touch your YubiKey when prompted)"
echo ""

TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
git init -q
git commit --allow-empty -S -m "Test signed commit" 2>/dev/null

SIGNATURE_CHECK=$(git log --show-signature -1 2>&1 | grep -E "Good|Bad" || true)
if echo "$SIGNATURE_CHECK" | grep -q "Good"; then
    echo -e "${GREEN}Commit signing works!${NC}"
else
    echo -e "${YELLOW}Signing works but verification might need the allowed_signers update.${NC}"
fi

cd - > /dev/null
rm -rf "$TEMP_DIR"
echo ""

# Summary
echo -e "${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "Configuration:"
echo "  Public key file:   ~/.ssh/${SIGNING_KEY_FILE}.pub"
echo "  Allowed signers:   ~/.ssh/allowed_signers"
echo "  Git signing:       enabled (commit.gpgsign = true)"
if [ -n "$ACCOUNT_NAME" ]; then
    echo "  Account:           $ACCOUNT_NAME"
fi
echo ""
echo "Git config:"
echo "  gpg.format:        $(git config --global --get gpg.format)"
echo "  user.signingkey:   $(git config --global --get user.signingkey)"
echo "  commit.gpgsign:    $(git config --global --get commit.gpgsign)"
echo ""
echo "Next steps:"
echo "  1. Add the public key to GitHub as both Auth and Signing key"
if [ -n "$ACCOUNT_NAME" ]; then
    echo "  2. Add to your $ACCOUNT_NAME GitHub instance settings"
    echo "  3. Use host alias '$ACCOUNT_NAME' in git remotes for this account"
    echo "     Example: git remote set-url origin git@${ACCOUNT_NAME}:org/repo.git"
else
    echo "  2. For additional accounts, run: $0 --generate-key --account github-emu"
fi
echo ""
echo "Public key to add to GitHub:"
echo ""
echo "$YUBIKEY_PUBKEY"
