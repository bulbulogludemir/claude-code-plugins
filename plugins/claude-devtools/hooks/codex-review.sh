#!/bin/bash
# Codex Review — manages multi-turn plan review with Codex CLI
# Usage: codex-review.sh round1|round2|round3 [project_dir]
#        Reads prompt from /tmp/codex-review/prompt.md (round1)
#        or /tmp/codex-review/counter-N.md (round2+)

set -euo pipefail

CODEX="/Users/demir/.npm-global/bin/codex"
ROUND="${1:-round1}"
PROJECT_DIR="${2:-$(pwd)}"
REVIEW_DIR="/tmp/codex-review"
TIMEOUT=180

# Portable timeout: run command in background, kill if exceeds TIMEOUT
run_with_timeout() {
  "$@" &
  local PID=$!
  (
    sleep "$TIMEOUT"
    kill "$PID" 2>/dev/null
  ) &
  local TIMER_PID=$!
  wait "$PID" 2>/dev/null
  local EXIT_CODE=$?
  kill "$TIMER_PID" 2>/dev/null
  wait "$TIMER_PID" 2>/dev/null
  return $EXIT_CODE
}

mkdir -p "$REVIEW_DIR"

case "$ROUND" in
  round1)
    PROMPT_FILE="$REVIEW_DIR/prompt.md"
    if [ ! -f "$PROMPT_FILE" ]; then
      echo "ERROR: No prompt file at $PROMPT_FILE" >&2
      exit 1
    fi

    echo "Starting Codex review (round 1, timeout ${TIMEOUT}s)..."
    echo "Project: $PROJECT_DIR"

    # Run Codex in read-only sandbox, output last message to file
    "$CODEX" exec \
      -s read-only \
      -C "$PROJECT_DIR" \
      --skip-git-repo-check \
      -o "$REVIEW_DIR/round1.txt" \
      - < "$PROMPT_FILE" 2>"$REVIEW_DIR/round1-stderr.txt" || {
        EXIT_CODE=$?
        echo "ERROR: Codex exited with code $EXIT_CODE" >&2
        cat "$REVIEW_DIR/round1-stderr.txt" >&2
        exit $EXIT_CODE
      }

    echo "=== Codex Round 1 Complete ==="
    echo "Output: $REVIEW_DIR/round1.txt"
    ;;

  round2|round3)
    ROUND_NUM="${ROUND#round}"
    COUNTER_FILE="$REVIEW_DIR/counter-${ROUND_NUM}.md"

    if [ ! -f "$COUNTER_FILE" ]; then
      echo "ERROR: No counter file at $COUNTER_FILE" >&2
      exit 1
    fi

    echo "Starting Codex review (round $ROUND_NUM)..."

    # Resume most recent session with Claude's counter-response
    # Note: resume doesn't support -o, so capture stdout directly
    NO_COLOR=1 "$CODEX" exec resume --last --skip-git-repo-check \
      - < "$COUNTER_FILE" > "$REVIEW_DIR/round${ROUND_NUM}.txt" 2>"$REVIEW_DIR/round${ROUND_NUM}-stderr.txt" || {
        EXIT_CODE=$?
        echo "ERROR: Codex exited with code $EXIT_CODE" >&2
        cat "$REVIEW_DIR/round${ROUND_NUM}-stderr.txt" >&2
        exit $EXIT_CODE
      }

    echo "=== Codex Round $ROUND_NUM Complete ==="
    echo "Output: $REVIEW_DIR/round${ROUND_NUM}.txt"
    ;;

  clean)
    rm -rf "$REVIEW_DIR"
    echo "Cleaned review directory"
    ;;

  *)
    echo "Usage: codex-review.sh round1|round2|round3|clean [project_dir]" >&2
    exit 1
    ;;
esac
