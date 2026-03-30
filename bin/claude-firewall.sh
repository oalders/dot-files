#!/bin/bash
set -euo pipefail

# Adapted from Anthropic reference devcontainer firewall
# Restricts outbound traffic to only necessary services

echo "Configuring firewall..."

# Flush existing rules
iptables -F
iptables -X
iptables -t nat -F 2>/dev/null || true
iptables -t mangle -F 2>/dev/null || true
ipset destroy allowed-domains 2>/dev/null || true

# Allow DNS
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p udp --sport 53 -j ACCEPT

# Allow SSH
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT

# Allow localhost
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Create ipset for allowed domains
ipset create allowed-domains hash:net

# Resolve and add allowed domains
for domain in \
    "api.anthropic.com" \
    "auth.anthropic.com" \
    "console.anthropic.com" \
    "statsig.anthropic.com" \
    "sentry.io" \
    "statsig.com" \
    "registry.npmjs.org" \
    "github.com" \
    "api.github.com"; do

    echo "  Allowing $domain..."
    ips=$(dig +noall +answer A "$domain" 2>/dev/null | awk '$4 == "A" {print $5}')
    if [ -n "$ips" ]; then
        while read -r ip; do
            ipset add allowed-domains "$ip" 2>/dev/null || true
        done <<< "$ips"
    else
        echo "  WARNING: Could not resolve $domain"
    fi
done

# Fetch and add GitHub IP ranges (short timeout — DNS-resolved IPs above suffice if this fails)
echo "  Fetching GitHub IP ranges..."
gh_ranges=$(curl -s --connect-timeout 3 --max-time 5 https://api.github.com/meta 2>/dev/null || true)
if [ -n "$gh_ranges" ] && echo "$gh_ranges" | jq -e '.web' >/dev/null 2>&1; then
    while read -r cidr; do
        [ -n "$cidr" ] && ipset add allowed-domains "$cidr" 2>/dev/null || true
    done < <(echo "$gh_ranges" | jq -r '(.web + .api + .git)[]' 2>/dev/null | grep -E '^[0-9]')
fi

# Allow LXC host network
HOST_IP=$(ip route | grep default | cut -d" " -f3)
if [ -n "$HOST_IP" ]; then
    HOST_NETWORK=$(echo "$HOST_IP" | sed "s/\.[0-9]*$/.0\/24/")
    iptables -A INPUT -s "$HOST_NETWORK" -j ACCEPT
    iptables -A OUTPUT -d "$HOST_NETWORK" -j ACCEPT
fi

# Set default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow only whitelisted destinations
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT

# Reject everything else
iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited

# Verify
echo ""
if curl --connect-timeout 5 https://example.com >/dev/null 2>&1; then
    echo "WARNING: Firewall check failed - example.com is reachable"
else
    echo "OK: Blocked traffic verified (example.com unreachable)"
fi

if curl --connect-timeout 5 https://api.anthropic.com >/dev/null 2>&1; then
    echo "OK: Anthropic API is reachable"
else
    echo "WARNING: Anthropic API unreachable - check firewall rules"
fi

echo "Firewall configured."
