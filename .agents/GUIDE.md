# IntentGuard Fork Guide

## Confirmed Direction

This workspace is a fork-ready copy of `zeriontech/zerion-ai`.

IntentGuard should build on top of Zerion CLI rather than wrapping it from a separate empty project. Zerion stays the wallet, routing, signing, and execution layer. IntentGuard adds autonomous intent handling, trigger monitoring, richer policy validation, and auditability.

## Current Layout Decision

The upstream Zerion CLI repository now lives at the workspace root.

IntentGuard planning documents are preserved in `docs/intentguard/` so they do not conflict with upstream files, especially `README.md` on Windows.

## Key Tradeoffs

Building inside the fork keeps package scripts, CLI commands, tests, and future patches close to upstream. This makes hackathon iteration faster and keeps changes reviewable.

The tradeoff is that IntentGuard changes must stay cleanly separated from upstream behavior where possible. New features should prefer new commands, new policy modules, or narrowly scoped extensions instead of broad rewrites.

## Implementation Constraints

Do not hardcode API keys, private keys, agent tokens, or wallet secrets.

Use Zerion's documented agent token and policy flow for real transactions. Treat agent tokens like credentials with spending power.

Before relying on specific CLI flags or output shape, verify the installed CLI behavior because Zerion CLI is marked Alpha Preview.
