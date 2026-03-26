# Trust Center Remediation

## Finding
**Migrate LEGACY SERVICE users away from password-only sign-ins**
- Scanner: `SECURITY_ESSENTIALS_STRONG_AUTH_LEGACY_SERVICE_USERS_READINESS`
- Package: `SECURITY_ESSENTIALS`

## What This Script Does
Remediates the Trust Center critical finding by migrating `LEGACY_SERVICE` users off password-only authentication. Handles two categories:

| User Type | Identified By | Remediation |
|-----------|--------------|-------------|
| Regular service accounts | `LEGACY_SERVICE` + password-only | Migrate to RSA key-pair auth, then remove password |
| SPCS service users | Name pattern `SVC_%_ENDPOINT_%` | Convert type: `ALTER USER SET TYPE = SERVICE` |

## How to Run

1. Run **Steps 1-3** (SELECT queries) to identify affected users
2. Replace `<USER_NAME>` / `<SPCS_USER_NAME>` placeholders with actual names from the results
3. Uncomment and run the relevant ALTER statements (Step 4 or 5)
4. Run **Steps 7-8** to verify — zero rows = finding cleared

## Notes
- `snowflake.account_usage.users` has **~2 hour latency** — use `SHOW USERS` (Step 7) for real-time verification
- The correct column is `type` (not `user_type`)
- Key-pair auth is recommended over OAuth for service accounts (simpler, no IdP setup)
- Trust Center rescans periodically — finding clears once all `LEGACY_SERVICE` users are remediated
