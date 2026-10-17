<p align="center"><img src="assets/logo.svg" width="56" alt="HALO Ops"></p>

# HALO Ops

**The operations layer under a one-person AI company.**

**Built for Dime Data's own operations** · source is private.

What this is: a text-only showcase of the operations layer. The source is private; this
repository describes the part worth reading.

## The problem

Unattended agents fail quietly. A model hits its usage limit, exits with status 0 and prints the
apology where the answer should be. A loop goes silent and looks exactly like one that was paused
on purpose. Every command file claims to follow the same rules, and nobody notices when
two of them stop. None of these throw an error, so each needs something that measures it.

## What it does

| | |
|---|---|
| **Officer loops** | Scheduled roles (outbound, inbound, funding, security, ops, legal and so on). Each owns a ledger, a cadence and a slice of a shared monthly send budget. |
| **Dispatcher** | Decides which loops are due, staggers them, and publishes its own state so a stopped supervisor is visible in every session. It stands down when the account hits a usage limit instead of firing into the wall. |
| **MCP server** | `halo_mcp` exposes suites (devops, capital, legal and others), each bound to a default model and effort. Claude work rotates across a pool of subscription seats and remembers which are throttled until their stated reset. |
| **Status board** | One script answers "what is running now". Staleness is judged against each loop's own cadence, not a global timeout, and skipped-on-purpose is shown separately from dead. |
| **Suite checker** | A suite of executable invariants over the command files, the shared contract and the hook: send allocations, cadence, ledger ownership, roster agreement and more. Drift prints what, where and the expected value. |

## How it works

```mermaid
flowchart LR
    D[Dispatcher<br/>due loops · stagger · stand-down] --> L[officer loops<br/>ledger · cadence · send share]
    L --> M[halo_mcp<br/>suites · model routing]
    M --> P[Seat pool<br/>classify · rotate · cooldown]
    D --> S[(State files<br/>status · gated)]
    S --> B[Status board<br/>NEVER · STALL · due · ok]
    C[Suite checker<br/>invariants] -. verifies .-> L
    C -. verifies .-> B
```

**Exit status is not a signal, so nothing trusts it.** Every Claude result goes through one
classifier that returns `throttled`, `auth`, `error`, `empty` or `ok`. Auth failures are kept apart
from throttling because rotating seats won't fix a dead token and retrying burns the pool.

**Staleness is relative.** A loop that runs hourly is not late at 90 minutes, and one that runs
daily is not healthy at 90 minutes. Three times its own cadence is a dead chain; one to three is
merely due.

**A rule nobody measures is a preference.** The checker exists because an audit found send
allocations summing past the company ceiling, a loop committing under a different prefix than its
sibling loops, and objection handling owned by more than one loop. None was visible without reading all
the files side by side.

## Built with

Node.js · Bash · PowerShell · Supabase (pool state) · Docker · Caddy · the Model Context Protocol.

## By the numbers

| | |
|---|---|
| Officer loops | **Scheduled roles**, each with its own ledger and cadence |
| Suite checker | **Executable** invariants over the command files and the shared contract |

## Status

Built for Dime Data's own operations. The source is private and this repository is
a showcase. © 2026 Dime Data, all rights reserved (see [LICENSE](LICENSE)). Built by
[Dime Data](https://dimedata.cloud).
