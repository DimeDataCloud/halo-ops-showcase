// Excerpt from a private codebase: halo-suite-os, services/claude-pool.js at 9d1bc42.
// Shown for reading. Not licensed for reuse; see ../LICENSE.
// The failure the file exists to prevent (its header comment), then ClaudePool.classify().
// classify() is a static method of the ClaudePool class; the rest of the class is not shown.
// The time zone in the sample message on line 10 of this file is removed.

// ── The failure this file exists to prevent ────────────────────────────────
// `claude -p` EXITS 0 AND PRINTS THE LIMIT MESSAGE TO STDOUT:
//
//     $ claude -p "Reply with exactly: PONG"; echo $?
//     You've hit your weekly limit · resets 6am
//     0
//
// So exit status carries no signal, and stdout is not necessarily an answer.
// A caller that trusts either one hands that sentence back to the user AS the
// model's reply — HALO saying "You've hit your weekly limit" as though it were
// content — and never falls back, because nothing threw. Every read of a
// Claude result in this codebase must go through classify() below.
//

// ...

class ClaudePool {
  /**
   * Read a Claude CLI result and say what it actually is.
   *
   * `text` is the CLI's combined output. `code` is its exit status, which is
   * deliberately advisory: a throttled run exits 0.
   */
  static classify(text, code) {
    const s = String(text || '');

    // Quota walls. Matched before any success check, because the message
    // arrives on stdout in the position an answer would occupy.
    //
    // Deliberately NOT an enumeration of limit types. The first version listed
    // weekly/usage/rate and was defeated within the hour by a real account
    // reporting "You've hit your session limit · resets 4:20pm" — the 5-hour
    // rolling window, which nobody had thought to list. Anthropic can add a
    // limit type whenever it likes, and each new one would be a silent
    // regression to the exact bug this function exists to prevent.
    //
    // So match the SHAPE instead: the word "limit" in the company of language
    // that only appears when you have run into one. Any adjective works.
    if (/\bquota\b/i.test(s) ||
        /\blimits?\b/i.test(s) && (
          /\b(hit|reached|exceeded|out of|exhausted)\b/i.test(s) ||   // "you've hit your … limit"
          /\bresets?\b/i.test(s) ||                                   // "… limit · resets 4:20pm"
          /\btry again\b/i.test(s)
        )) {
      return { kind: 'throttled', resetAt: ClaudePool.parseReset(s), detail: s.trim().split('\n')[0] };
    }
    // Auth problems are NOT throttling: rotating to another seat will not help
    // if the token is simply dead, and retrying burns the pool.
    if (/invalid.*(api key|token)|unauthor|authentication|not logged in|please run .*login/i.test(s)) {
      return { kind: 'auth', detail: s.trim().split('\n')[0] };
    }
    if (code !== 0) {
      return { kind: 'error', detail: s.trim().split('\n')[0] || `exited ${code}` };
    }
    if (!s.trim()) {
      return { kind: 'empty', detail: 'no output' };
    }
    return { kind: 'ok', output: s };
  }
}
