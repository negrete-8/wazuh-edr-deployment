# wazuh-edr-deployment

![Wazuh](https://img.shields.io/badge/Wazuh-4.7.5-FF6F00?logo=wazuh&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)
![Debian](https://img.shields.io/badge/Debian-Server-A81D33?logo=debian&logoColor=white)
![Blue Team](https://img.shields.io/badge/Blue%20Team-EDR-1e3a8a)

End-to-end deployment of **Wazuh** as an Endpoint Detection and Response (EDR) platform. Covers the full lifecycle from infrastructure setup to active response automation and vulnerability management, simulating an Incident Response Analyst role.

## Architecture

```
                  ┌─────────────────────────────────────┐
                  │       Wazuh Server (Debian)         │
                  │   ┌────────────────────────────┐    │
                  │   │  Docker Compose stack       │    │
                  │   │  ├── wazuh.manager          │    │
                  │   │  ├── wazuh.indexer          │    │
                  │   │  └── wazuh.dashboard        │    │
                  │   └────────────────────────────┘    │
                  └─────────────────────────────────────┘
                              ▲          ▲
                              │ 1514/TCP │ 1515/TCP
                              │ (events) │ (enrollment)
                              │          │
                  ┌─────────────────────────────────────┐
                  │      Wazuh Agent (Debian endpoint)  │
                  │  ├── Process / port inventory       │
                  │  ├── FIM (file integrity)           │
                  │  ├── Rootcheck                      │
                  │  ├── SCA (CIS benchmarks)           │
                  │  ├── Vulnerability detection (CVE)  │
                  │  └── Active Response (iptables)     │
                  └─────────────────────────────────────┘
```

## What's Covered

- 🐳 Docker Compose single-node deployment of Wazuh 4.7.5
- 🔐 Agent enrollment with mutual TLS
- 👁️ Endpoint telemetry: processes, ports, packages, FIM, Rootcheck
- ⚡ Active Response: SSH brute-force auto-block + host isolation
- 🛡️ Vulnerability management (NVD / Canonical / Debian CVE feeds)
- 📊 SCA against CIS Benchmarks
- 🎯 MITRE ATT&CK event mapping
- 📋 Compliance modules (PCI DSS, HIPAA, NIST, TSC, GDPR)

## Quick Reference

| Component | Port | Protocol | Purpose |
|-----------|------|----------|---------|
| Agent → Manager | 1514 | TCP | Encrypted event traffic |
| Agent registration | 1515 | TCP | Enrollment via `authd` |
| API REST | 55000 | TCP | Dashboard ↔ Manager |
| Dashboard | 443 | HTTPS | Web UI |

## Documentation

| Document | Description |
|----------|-------------|
| [Deployment Guide](./docs/deployment.md) | Full step-by-step server + agent setup |
| [Active Response](./docs/active-response.md) | Automated blocking and host isolation |
| [Key Concepts (Q&A)](./docs/key-concepts.md) | EDR fundamentals: zero-day detection, FIM, Zero Trust, CIA triad |

## Configuration Snippets

| File | Use |
|------|-----|
| [`config/active-response.xml`](./config/active-response.xml) | SSH brute-force auto-block + isolation block |
| [`config/agent-install.sh`](./config/agent-install.sh) | One-liner agent install for Debian/Ubuntu |

## Use Cases Implemented

1. **SSH brute-force defense** — rule 5712 + `firewall-drop` Active Response → IP blocked 600 seconds via iptables
2. **Compromised host isolation** — custom Active Response allowing only manager comms on 1514/1515 while blocking all other traffic
3. **Continuous vuln management** — agent inventory cross-referenced against NVD/Canonical/Debian/Red Hat CVE feeds
4. **Hardening audit** — SCA module evaluates against CIS Benchmarks (password policy, services, file permissions)

## Related Repositories

- [linux-hardening-lab](https://github.com/negrete-8/linux-hardening-lab) — SSH bastion + Cowrie honeypot Vagrant lab
- [threat-intelligence](https://github.com/negrete-8/threat-intelligence) — IOCs that would feed into Wazuh custom rules
- [honeypot](https://github.com/negrete-8/honeypot) — Source of attacker telemetry

## Legal Notice

> Lab environment deployment. Wazuh is open source and free for commercial use.
> Do not deploy agents on systems you do not own or lack written authorization to monitor.
