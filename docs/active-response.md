# Active Response — Automated Defense

Wazuh's Active Response framework allows the manager to instruct agents to execute defensive scripts on the endpoint in reaction to specific alerts. This document covers the two scenarios implemented in this deployment.

## Scenario 1 — SSH Brute-Force Auto-Block

**Goal:** automatically block attacker IPs performing SSH brute-force attempts.

**Trigger:** Wazuh rule **5712** — "SSHD brute force attack" — fires when multiple failed authentication attempts come from the same source within a short window.

**Response:** the built-in `firewall-drop` Active Response adds an iptables rule that drops all traffic from the offending IP for a defined timeout.

### Configuration

In `/var/ossec/etc/ossec.conf` on the manager:

```xml
<active-response>
  <command>firewall-drop</command>
  <location>local</location>
  <rules_id>5712</rules_id>
  <timeout>600</timeout>
</active-response>
```

| Field | Meaning |
|-------|---------|
| `command` | Predefined Wazuh response (`firewall-drop` ships with the agent) |
| `location` | `local` = execute on the agent that generated the alert |
| `rules_id` | Triggering rule (5712 = SSH brute force) |
| `timeout` | How long the block persists (600 s = 10 min) |

### Result

When an attacker hits the threshold of failed SSH logins:

1. Agent forwards events to the manager
2. Manager correlates and fires rule 5712
3. Manager instructs the agent to run `firewall-drop`
4. Agent adds: `iptables -I INPUT -s <ATTACKER_IP> -j DROP`
5. After 600 s, the rule is automatically removed

---

## Scenario 2 — Host Isolation

**Goal:** when an endpoint is suspected of being compromised, isolate it from the network to prevent lateral movement while preserving the Wazuh agent ↔ manager link for forensic investigation.

**Trigger:** manual — invoked by the analyst from the dashboard against a specific agent.

**Response:** a custom Active Response that flushes the firewall and allows **only** traffic to the Wazuh Manager on ports 1514 (events) and 1515 (enrollment), blocking everything else.

### Custom command (concept)

```bash
#!/bin/bash
# isolate-host.sh - Active Response script
# Flush existing rules
iptables -F
iptables -X

# Default deny
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow ESTABLISHED connections (so the existing Wazuh tunnel doesn't drop)
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow traffic to/from Wazuh Manager on 1514 and 1515
iptables -A OUTPUT -d <MANAGER_IP> -p tcp --dport 1514 -j ACCEPT
iptables -A OUTPUT -d <MANAGER_IP> -p tcp --dport 1515 -j ACCEPT
iptables -A INPUT  -s <MANAGER_IP> -p tcp --sport 1514 -j ACCEPT
iptables -A INPUT  -s <MANAGER_IP> -p tcp --sport 1515 -j ACCEPT
```

### Operational notes

- **Reversible** — implement a paired `unisolate-host.sh` that restores the previous ruleset (saved before isolation with `iptables-save`).
- **Audit trail** — Wazuh logs the invocation, so the SOC retains a record of who isolated which host and when.
- **Forensic access** — the manager channel remains open, so the analyst can still query the agent for processes, file hashes and recent events while the host is contained.

---

## Risks of Automating Active Responses

| Risk | Mitigation |
|------|------------|
| False positive blocks legitimate traffic | Run rule in **observation mode** for a tuning window before enabling auto-action |
| Self-DoS during a stress event | Add allowlist for internal monitoring / admin IPs |
| Attacker forces Active Response on legitimate IPs (DoS-as-a-feature) | Tune detection thresholds; require multiple signals to trigger |
| Race condition with backup / patching jobs | Schedule maintenance windows where Active Response is paused |

Active Response is powerful but must be tuned against the production environment. The recommendation is to deploy detections in **alert-only** mode first, validate over a baseline window, and only then enable the response action.
