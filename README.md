# Secret Sentinel — Developer Preview
Secret Sentinel is a lightweight PowerShell-based scanner that checks source files for patterns resembling hardcoded credentials.
## Run
Launch SecretSentinel-Launcher.ps1 and choose a scan option.
## Current detection patterns
- AWS access keys
- Google API keys
- GitHub tokens
- Slack tokens
- Stripe live keys
- Private-key headers
- Possible API tokens
- Possible hardcoded passwords
## Limitations
This is a heuristic scanner, not a complete security audit. It can miss secrets and produce false positives. Review findings manually and use dedicated security tools for production assurance.
Reports may contain surrounding source-code context. Treat reports as sensitive and review them before sharing.
