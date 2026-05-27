# EDR Key Concepts

Reference notes covering EDR fundamentals — useful for interviews and for understanding the design decisions behind this deployment.

---

## How does an EDR detect a zero-day?

Unlike signature-based antivirus, an EDR relies on **behavioural analysis and event correlation**. Instead of looking for a specific hash, it detects suspicious patterns:

- An office process spawning PowerShell
- Unusual writes to system directories
- Connections to never-before-seen IPs
- Unexpected privilege escalation chains

Because it does not need prior knowledge of the threat, it can flag new attacks by how they **act**, not by what they **look like**.

---

## Why is File Integrity Monitoring (FIM) vital for persistence detection?

To survive reboots, an attacker must modify system files: cron jobs, systemd units, `/etc/rc.local`, authorized SSH keys, the Windows registry, etc.

FIM computes hashes of critical files and detects any change, alerting whenever modifications appear in paths that should normally be static. It is the most direct way to catch persistence mechanisms.

---

## Passive vs Active Response — and the risks of automation

| Mode | Action |
|------|--------|
| **Passive** | Generate an alert; analyst investigates |
| **Active** | Automated action — block IP, kill process, isolate host |

**Risks of active response:**

- **False positives** disrupt production: a misfired rule can DoS legitimate users, abort a critical update, or isolate a production server.
- **Self-DoS** — an attacker can craft requests that intentionally trigger your blocks.
- **Cascading actions** — one false positive can chain into more.

Active rules should be deployed in **observation mode** first, baselined, then promoted to enforcement only after tuning.

---

## How does EDR fit into Zero Trust?

Zero Trust assumes **no device is trusted by default**, even inside the network perimeter. The EDR reinforces this by continuously verifying endpoint behaviour: passing the initial authentication is not enough — the host must keep behaving normally.

If an authorized device starts behaving anomalously, the EDR detects and responds, because it operates on the assumption that **any host can be compromised**.

---

## If an attacker deletes local logs, why can the analyst still investigate from the Manager?

Because the agent forwards events to the manager **in real time**. By the time an event occurs, the data is already replicated to the central server.

Even if the attacker wipes `/var/log` on the endpoint, the copy is already outside their reach on the manager — a direct application of **centralised logging** to incident response.

---

## Why is an agent more efficient than monthly scans for vulnerability management?

An external scan is a **point-in-time snapshot** that goes stale the next day. An agent maintains:

- A **real-time inventory** of installed packages and versions
- **Automatic re-evaluation** every time NVD/Canonical/Debian publish a new CVE
- **No network noise** — the data comes from the endpoint itself, no scanning required
- **No reachability issues** — works on laptops, VPN-only hosts, ephemeral cloud instances

---

## EDR blocks a legitimate IT tool — how to tune it?

1. Identify the **rule ID** that fired (visible in the alert logs)
2. Add a local exception based on:
   - Binary hash
   - File path
   - Executing user
   - Hostname
3. Reload Wazuh

The system continues monitoring everything else but recognizes this specific usage as legitimate, eliminating the false positive without lowering overall detection.

---

## What network information does an EDR give that a perimeter firewall doesn't?

A firewall sees **IPs, ports, packets**. It cannot tell you **which process** on the endpoint generated a given connection.

An EDR can: e.g. `/usr/bin/curl` invoked by user `www-data` opened a connection to the suspicious IP. That **process-to-connection traceability** is the missing piece for real incident investigation, because it links network behaviour to the specific application that caused it.

---

## 5,000 remote employees — why EDR beats forcing VPN through the firewall?

- Routing 5,000 users through the office VPN is a **bandwidth bottleneck** and adds latency.
- An EDR installs on each laptop and protects the employee **wherever they are**, no perimeter dependency.
- Plus, the EDR sees **endpoint behaviour**, not just network traffic — information the office firewall would never have.

---

## Which part of the CIA triad benefits most from active EDR response?

**Integrity** and **Confidentiality**:

- Killing a malicious process or isolating an infected host prevents the attacker from **altering files** (integrity) and **exfiltrating data** (confidentiality).

**Availability** can paradoxically be hurt by a false-positive block — but the net balance is positive, because an unmitigated attack also impacts availability when the system ultimately fails.
