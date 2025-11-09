# GhostChip (Open-Source Mobile Forensics POC)

Portable, open-source toolkit for NIST-aligned mobile forensics workflows.

## Quick Start
```bash
chmod +x scripts/*.sh
./scripts/ghost_init_case.sh
./scripts/ghost_acquire.sh Cases/Case_YYYYMMDD_HHMMSS
python3 report/ghost_report.py Cases/Case_YYYYMMDD_HHMMSS
```

## Structure
- scripts/: shell scripts (init, acquire, integrity, update, installer)
- report/: HTML/JSON report generator
- validation/: sample inputs + checks
- templates/: report templates
- docs/: SOPs & implementation notes
- .github/workflows/pack.yml: release packager CI

## License
MIT (see LICENSE)
