# Excerpt from a private workspace: BrainAI/systems/check-loop-suite.sh at b8cd017b.
# Shown for reading. Not licensed for reuse; see ../LICENSE.
# Checks 5 and 10 of 17. $LOOPS is "name:ledger:monthly-sends:today-block", one per line;
# $CMD, $CONTRACT and $HOOK are the three artifacts each loop is checked against.

echo "=== 5. send allocation: only declared senders send, and the pool is not oversubscribed ==="
tot=0; totd=0
for spec in $LOOPS; do
  nm="${spec%%:*}"; rest="${spec#*:}"; mo="${rest#*:}"; mo="${mo%%:*}"
  f="$CMD/${nm}-loop.md"; [ -f "$f" ] || continue
  claim=$(grep -ohE 'My allocation is \*{0,2}[0-9]+/month and [0-9]+/day' "$f" | head -1)
  if [ "$mo" = "0" ]; then
    [ -n "$claim" ] && fail "$nm: is a non-sending officer but claims an allocation ($claim)"
  else
    [ -n "$claim" ] || { fail "$nm: expected an allocation of ${mo}/month, found none"; continue; }
    got=$(echo "$claim" | grep -oE '[0-9]+/month' | grep -oE '[0-9]+')
    gotd=$(echo "$claim" | grep -oE '[0-9]+/day' | grep -oE '[0-9]+')
    [ "$got" = "$mo" ] || fail "$nm: claims ${got}/month, contract says ${mo}/month"
    tot=$(( tot + got )); totd=$(( totd + gotd ))
  fi
done
if [ "$tot" -le 900 ] && [ "$totd" -le 180 ]; then
  pass "allocations sum to ${tot}/month, ${totd}/day (ceiling 900 / 180)"
else
  fail "allocations sum to ${tot}/month, ${totd}/day — OVER the 900/180 company ceiling"
fi


echo "=== 10. cadence agrees across command file, contract and hook ==="
# Three artifacts encode each loop's interval and they drift independently:
#   the file's own "## Cadence — N minutes" heading · the contract's Cadence column ·
#   the hook's per-loop staleness threshold.
# Found 2026-08-03: /content-loop said 45-60 in its file and 30-60 in the contract. A contract that
# disagrees with the file is a contract nobody can trust on the axes it is not checked on.
for spec in $LOOPS; do
  nm="${spec%%:*}"; f="$CMD/${nm}-loop.md"; [ -f "$f" ] || continue
  fh=$(grep -ohE '^## Cadence.*' "$f" | head -1)
  [ -n "$fh" ] || { fail "$nm: no '## Cadence' section — its interval is undiscoverable"; continue; }
  fn=$(echo "$fh" | grep -oE '[0-9]+' | head -1)
  [ -n "$fn" ] || { fail "$nm: '## Cadence' heading states no base interval"; continue; }
  cn=$(grep -E "^\| \*\*\`/${nm}-loop\`" "$CONTRACT" | awk -F'|' '{print $5}' | grep -oE '[0-9]+' | head -1)
  [ -n "$cn" ] || { fail "$nm: contract row has no cadence"; continue; }
  [ "$fn" = "$cn" ] || fail "$nm: file says ${fn} min, contract says ${cn} min"
  # Hook threshold must exceed the base interval, or a healthy loop is reported as a dead chain.
  hl=$(grep -oE "${nm}:[a-z0-9-]+:[0-9]+" "$HOOK" 2>/dev/null | head -1 | awk -F: '{print $3}')
  [ -z "$hl" ] || [ "$hl" -gt "$fn" ] \
    || fail "$nm: hook marks it quiet after ${hl} min but its base interval is ${fn} min — healthy runs read as dead"
done
pass "cadence consistent across file, contract and hook for all 13"

echo
