# Wazuh EDR — Deployment Guide

End-to-end installation of a Wazuh 4.7.5 manager (Docker single-node) and a Linux agent.

## Scenario

The deployment simulates the role of an **Incident Response Analyst**. The objective is not only to prevent malware from entering the system but also to detect what it does once inside and automate response actions on the endpoints.

Unlike perimeter solutions (firewall, IDS/IPS) that only see network traffic, an EDR like Wazuh operates **directly on the endpoint**, acting as the system's "black box": it logs what happens, detects anomalous behaviour and allows real-time response.

The deployment uses a client-server model:

- **Wazuh Manager** — centralized server running on Docker on a dedicated Debian VM
- **Wazuh Agent** — installed on another Debian endpoint, collects and forwards telemetry

---

## Phase 1 — Trust Infrastructure (PKI & Server)

### Deploy the Wazuh server

The single-node Docker Compose deployment bundles the full stack (manager, indexer, dashboard) on a single host.

```bash
git clone https://github.com/wazuh/wazuh-docker.git -b v4.7.5 --depth=1
cd wazuh-docker/single-node
docker compose up -d
```

After a few minutes the three main containers are running:

- `wazuh.manager`
- `wazuh.indexer`
- `wazuh.dashboard`

Access the admin panel at `https://<server-ip>`.

### Retrieve the default admin password

```bash
docker inspect single-node-wazuh.dashboard-1 | grep -i "INDEXER_PASSWORD"
# default: SecretPassword
```

### Agent installation

In the Wazuh dashboard, navigate to **Add agent** and select:
- OS family: Linux / DEB / amd64
- Manager IP: server VM address
- Agent name: arbitrary identifier

The wizard generates the install one-liner — execute it on the endpoint:

```bash
wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.7.5-1_amd64.deb
sudo WAZUH_MANAGER='<SERVER_IP>' dpkg -i ./wazuh-agent_4.7.5-1_amd64.deb
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent
```

### Verify connectivity

In the dashboard, **Agents** section, the endpoint should appear with status **Active**.

| Port | Protocol | Purpose |
|------|----------|---------|
| 1514 | TCP | Encrypted agent → manager events |
| 1515 | TCP | Agent enrollment via `authd` |
| 55000 | TCP | Manager REST API (used by dashboard) |

---

## Phase 2 — Visibility & Telemetry

Once the agent is communicating, Wazuh begins collecting host-level data.

### Process and inventory monitoring

**Agents → (endpoint) → Inventory data**

Shows the complete system inventory:

- Running processes
- Open ports
- Installed packages
- Local users and groups
- Hardware
- Network interfaces

This visibility surfaces unauthorized processes, anomalous network connections, or unapproved software.

### Rootkit detection

**Modules → Rootcheck**

Detects kernel-level anomalies, hidden files, mismatches between `/proc` and `ps`, and other rootkit indicators that signature-based AV would miss.

### Built-in monitoring modules

| Module | Purpose |
|--------|---------|
| Security Events | Rule-correlated security events |
| Integrity Monitoring (FIM) | Detect changes to critical files |
| SCA | Hardening audit against CIS Benchmarks |
| Vulnerability Detection | CVE matching against installed packages |
| MITRE ATT&CK | Map events to tactics and techniques |
| PCI DSS / HIPAA / NIST / TSC / GDPR | Compliance dashboards |
| Rootcheck | Rootkit and system anomaly detection |
| System Inventory | Processes, ports, packages, hardware |

---

## Phase 3 — Active Response

Up to this point, Wazuh only observes and alerts. The real value of an EDR emerges when responses are automated: the system reacts to threats without waiting for human intervention.

See [active-response.md](./active-response.md) for the full configuration of:

- **SSH brute-force auto-block** — built-in `firewall-drop` triggered by rule 5712
- **Host isolation** — custom Active Response allowing only manager communication

---

## Phase 4 — Vulnerability Management & Compliance

### Application inventory

**Agents → (endpoint) → Inventory data → Packages**

Lists all installed software with exact versions. This inventory is the foundation for vulnerability detection.

### CVE detection

The vulnerability module cross-references installed packages against:

- **NVD** (National Vulnerability Database)
- **Canonical** (Ubuntu USN)
- **Debian** Security Advisories
- **Red Hat** OVAL feeds

Each finding is shown with:

- CVE ID
- Severity (Low / Medium / High / Critical)
- CVSS score
- Affected package and version

This enables risk-based patching instead of generic "updates available" lists.

### Security Configuration Assessment (SCA)

**Modules → Security Configuration Assessment**

Evaluates the system against **CIS Benchmarks**:

- Password policy strength
- Unnecessary services running
- Permissive file permissions
- Audit settings, kernel parameters, etc.

The first scan runs after a short delay. Subsequent scans are periodic and show:

- Overall compliance percentage
- List of failed checks with remediation guidance
- Trend over time

---

## Verification Checklist

- [ ] Three Wazuh containers running (`docker ps`)
- [ ] Dashboard accessible on `https://<server-ip>`
- [ ] At least one agent registered with status `Active`
- [ ] Inventory data populated (processes, packages, ports)
- [ ] Active Response configured in `/var/ossec/etc/ossec.conf`
- [ ] SCA scan completed at least once
- [ ] Vulnerability module showing scan results (may take time on first run)
