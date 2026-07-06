# ADR-001: Enable MFA for All Azure Users

## Date: 2026-07-06
## Status: Accepted

## Context
Defender for Cloud flagged that accounts in the tenant do not have MFA
enabled. This is a High severity finding. Without MFA, a compromised
password gives an attacker full account access with no second barrier.
MFA is one of the most effective controls against credential-based attacks.

## Options Considered
1. Enable Security Defaults (Microsoft-managed, enables MFA for all users)
2. Create a Conditional Access Policy requiring MFA for all users
3. Do nothing — accept the risk

## Trade-offs
Option 1 is simpler to enable but less flexible — no exceptions possible
for break-glass accounts. Option 2 allows break-glass account exclusions
while still enforcing MFA broadly. Option 3 leaves accounts exposed and
is not acceptable for any production environment.

## Decision
Option 2 — Conditional Access Policy. Provides flexibility for break-glass
accounts while enforcing MFA for all standard users.

## Consequences
All standard users must register MFA. Break-glass accounts are excluded
from the policy but monitored — any sign-in on a break-glass account
triggers an alert for immediate investigation. Secure Score is expected
to increase once MFA registration is complete across all accounts.
