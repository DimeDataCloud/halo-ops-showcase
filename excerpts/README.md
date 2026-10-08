# Excerpts

Three files from the private HALO ops source, copied unchanged apart from a header. Where the
excerpt starts or stops mid-file, the header says so. Each one is small enough to read on its own.

| File | Why it's here |
|---|---|
| [`claude-classify.js`](claude-classify.js) | The Claude CLI exits 0 and prints "you've hit your limit" to stdout, in the slot an answer would occupy. `classify()` is the one function every result passes through. It matches the shape of a limit message rather than a list of limit types, because the list was beaten within the hour by a limit nobody had listed. |
| [`status-precedence.sh`](status-precedence.sh) | Two ladders that decide what the status board says. A loop is `NEVER`, `STALL`, `due` or `ok` against its own cadence. The dispatcher is `limited`, `paused`, up, or not running, and deliberately skipped officers are reported as gated so they don't read as dead. |
| [`check-loop-suite.sh`](check-loop-suite.sh) | Checks 5 and 10 of 17. Check 5 fails when the declared send allocations oversubscribe the monthly or daily ceiling. Check 10 fails when a loop's cadence disagrees across its command file, the shared contract and the session hook. |

These files aren't licensed for reuse. They're here to show how the system is built.
