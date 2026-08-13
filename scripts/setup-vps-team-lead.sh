#!/usr/bin/env bash
set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
    echo "Chay script bang sudo: sudo ./scripts/setup-vps-team-lead.sh"
    exit 1
fi

read -r -p "Username Linux cho nhom truong: " LEAD_USER
if [[ ! "$LEAD_USER" =~ ^[a-z][a-z0-9_-]{2,31}$ ]]; then
    echo "Username khong hop le."
    exit 1
fi

echo "Dan SSH public key cua nhom truong (bat dau bang ssh-ed25519/ssh-rsa/ecdsa-):"
read -r LEAD_PUBLIC_KEY
if [[ ! "$LEAD_PUBLIC_KEY" =~ ^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp)\  ]]; then
    echo "SSH public key khong hop le."
    exit 1
fi

if ! id "$LEAD_USER" >/dev/null 2>&1; then
    adduser "$LEAD_USER"
fi

# Docker group is effectively root-equivalent. Only the team lead receives it.
usermod -aG sudo,docker "$LEAD_USER"

LEAD_HOME="$(getent passwd "$LEAD_USER" | cut -d: -f6)"
install -d -m 700 -o "$LEAD_USER" -g "$LEAD_USER" "$LEAD_HOME/.ssh"
touch "$LEAD_HOME/.ssh/authorized_keys"
if ! grep -qxF "$LEAD_PUBLIC_KEY" "$LEAD_HOME/.ssh/authorized_keys"; then
    printf '%s\n' "$LEAD_PUBLIC_KEY" >> "$LEAD_HOME/.ssh/authorized_keys"
fi
chown "$LEAD_USER:$LEAD_USER" "$LEAD_HOME/.ssh/authorized_keys"
chmod 600 "$LEAD_HOME/.ssh/authorized_keys"

systemctl enable docker nginx fail2ban >/dev/null

echo
echo "Da cap cho $LEAD_USER:"
echo "  - SSH bang public key"
echo "  - sudo"
echo "  - Docker (quyen quan tri cao)"
echo
echo "Hay mo mot terminal moi va thu SSH/sudo/docker truoc khi dong phien hien tai."
