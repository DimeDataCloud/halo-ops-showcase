# Excerpt from a private workspace: BrainAI/systems/halo-status.sh at 76664090.
# Shown for reading. Not licensed for reuse; see ../LICENSE.
# Two precedence ladders from the status script. Everything between them is not shown.

# --- ladder 1: a loop's freshness, judged against its OWN cadence ---
  # Overdue against its OWN cadence: 3x is a dead chain, not a slow iteration.
  if   [ "$mins" -ge 999999 ];            then flag="NEVER"
  elif [ "$mins" -gt $(( cad * 3 )) ];    then flag="STALL"
  elif [ "$mins" -gt "$cad" ];            then flag="due  "
  else                                         flag="ok   "
  fi

# --- ladder 2: dispatcher state; first match wins, "gated" is reported separately ---
if [ -f "$CACHE/dispatch-status" ]; then
  read -r dv dt dw < <(tr -d '\r\357\273\277' < "$CACHE/dispatch-status")
  case "${dt:-}" in (*[!0-9]*|"") dt=0 ;; esac
  case "${dv:-}" in
    limited) echo "  dispatch STOOD DOWN — account usage limit, resets ${dw:-?}" ;;
    paused)  echo "  dispatch UP but PAUSED — dispatching nothing by design" ;;
    # Token 1 is the in-flight officer count. The supervisor writes this every minute, so a
    # timestamp older than that is a stopped supervisor, not a quiet one.
    *)       printf "  dispatch up, %s in flight (wrote %sm ago)\n" \
                    "${dv:-?}" "$(( (NOW - dt)/60 ))" ;;
  esac
else
  echo "  dispatch NOT RUNNING — no supervisor; officers only move when invoked ([[systems/loop-dispatcher]])"
fi
if [ -s "$CACHE/dispatch-excluded" ]; then
  # Deliberately skipped officers look exactly like dead ones in the liveness list above.
  while read -r xk xn; do
    [ -n "${xn:-}" ] || continue
    printf "  gated    %s — %s (skipped on purpose, not broken)\n" "$xn" "$xk"
  done < <(tr -d '\r\357\273\277' < "$CACHE/dispatch-excluded")
fi
