#!/usr/bin/env bash
# Claude Code status line.
# Front segment: Dracula-style prompt (dir + git branch, from ZSH_THEME=dracula)
# Interface: Last query | This session | Today | This week | Context window
#   - "This session" = total cost of THIS conversation        (like `ccusage session`)
#   - "Today"/"This week" = cost across ALL local conversations (like `ccusage daily`)
# Dollar values render white+bold, everything else grey.

input=$(cat)

transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')
model_id=$(echo "$input" | jq -r '.model.id // "claude-sonnet-4"')
ctx_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
last_input=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
last_output=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // 0')
last_cache_write=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
last_cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')

# --- Cost calculation: one Python pass over the transcript files -------------
costs=$(python3 - "$transcript_path" "$model_id" \
  "$last_input" "$last_output" "$last_cache_write" "$last_cache_read" <<'PYEOF'
import sys, os, json, glob, datetime

transcript_path = sys.argv[1]
model_id        = sys.argv[2]
last_in, last_out, last_cw, last_cr = (int(x) for x in sys.argv[3:7])

# Pricing per million tokens: (input, output, cache_write, cache_read).
# Source: LiteLLM model_prices (same data ccusage uses). Note Opus dropped from
# $15/$75 to $5/$25 starting with 4.5 — billing 4.5+ at the old rate ~3x overcounts.
def pricing(model):
    m = (model or "").lower()
    if "opus" in m:
        if "opus-4-1" in m or "opus-4-2025" in m or "opus-3" in m or "3-opus" in m:
            return (15.0, 75.0, 18.75, 1.50)   # Opus 3 / 4.0 / 4.1
        return (5.0, 25.0, 6.25, 0.50)         # Opus 4.5+
    if "haiku" in m:
        if "haiku-4" in m:
            return (1.0, 5.0, 1.25, 0.10)      # Haiku 4.5
        return (0.80, 4.0, 1.0, 0.08)          # Haiku 3.5
    return (3.0, 15.0, 3.75, 0.30)             # Sonnet (default)

def cost(model, inp, out, cw, cr):
    pi, po, pcw, pcr = pricing(model)
    return inp*pi/1e6 + out*po/1e6 + cw*pcw/1e6 + cr*pcr/1e6

def toks(u):
    return (u.get("input_tokens", 0) or 0,
            u.get("output_tokens", 0) or 0,
            u.get("cache_creation_input_tokens", 0) or 0,
            u.get("cache_read_input_tokens", 0) or 0)

def assistant_usages(fp):
    """Yield (msg, message, usage) for each assistant turn with usage data."""
    try:
        with open(fp) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    msg = json.loads(line)
                except Exception:
                    continue
                if msg.get("type") != "assistant":
                    continue
                m = msg.get("message", {})
                u = m.get("usage")
                if u:
                    yield msg, m, u
    except OSError:
        return

# Time buckets, in local time.
now          = datetime.datetime.now().astimezone()
tz           = now.tzinfo
today_start  = now.replace(hour=0, minute=0, second=0, microsecond=0)
week_start   = today_start - datetime.timedelta(days=today_start.weekday())  # Monday
week_epoch   = week_start.timestamp()

def parse_ts(s):
    if not s:
        return None
    try:
        if s.endswith("Z"):
            s = s[:-1] + "+00:00"
        dt = datetime.datetime.fromisoformat(s)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=datetime.timezone.utc)
        return dt.astimezone(tz)
    except Exception:
        return None

# Locate every transcript directory (this device). Mirrors ccusage's scan of
# ~/.claude/projects, plus CLAUDE_CONFIG_DIR overrides and the live session's dir.
dirs = []
if transcript_path:
    dirs.append(os.path.dirname(os.path.dirname(transcript_path)))
dirs.append(os.path.join(os.path.expanduser("~"), ".claude", "projects"))
for d in (os.environ.get("CLAUDE_CONFIG_DIR") or "").split(","):
    if d.strip():
        dirs.append(os.path.join(d.strip(), "projects"))

files = []
for d in dirs:
    if d and os.path.isdir(d):
        files.extend(glob.glob(os.path.join(d, "**", "*.jsonl"), recursive=True))
files = list(dict.fromkeys(os.path.realpath(f) for f in files))  # dedup
session_real = os.path.realpath(transcript_path) if transcript_path else None

# This session: sum all assistant turns in the current conversation file.
session_cost = 0.0
seen_session = set()
if session_real and os.path.exists(session_real):
    for _, m, u in assistant_usages(session_real):
        mid = m.get("id")
        if mid:
            if mid in seen_session:
                continue
            seen_session.add(mid)
        session_cost += cost(m.get("model") or model_id, *toks(u))

# Today / this week: sum across all conversations, deduping by (message id, request id).
today_cost = 0.0
week_cost  = 0.0
seen = set()
for fp in files:
    try:
        if os.path.getmtime(fp) < week_epoch:  # nothing from this week → skip file
            continue
    except OSError:
        continue
    for msg, m, u in assistant_usages(fp):
        key = (m.get("id"), msg.get("requestId"))
        if key[0] and key in seen:
            continue
        if key[0]:
            seen.add(key)
        ts = parse_ts(msg.get("timestamp"))
        if not ts:
            continue
        c = cost(m.get("model") or model_id, *toks(u))
        if ts >= week_start:
            week_cost += c
        if ts >= today_start:
            today_cost += c

last_cost = cost(model_id, last_in, last_out, last_cw, last_cr)

def fmt(c):
    if c >= 1.0:   return "${:.2f}".format(c)
    if c >= 0.001: return "${:.4f}".format(c)
    if c == 0:     return "$0"
    return "${:.6f}".format(c)

print(fmt(session_cost))
print(fmt(today_cost))
print(fmt(week_cost))
print(fmt(last_cost))
PYEOF
)

session_cost=$(echo "$costs" | sed -n '1p')
today_cost=$(echo "$costs" | sed -n '2p')
week_cost=$(echo "$costs" | sed -n '3p')
last_cost=$(echo "$costs" | sed -n '4p')

# --- Context window fill bar (5 segments) -----------------------------------
ctx_bar=""
if [ -n "$ctx_used" ]; then
  pct=$(printf "%.0f" "$ctx_used" 2>/dev/null || echo "0")
  filled=$(( pct * 5 / 100 ))
  empty=$(( 5 - filled ))
  bar=""
  for i in $(seq 1 "$filled"); do bar="${bar}█"; done
  for i in $(seq 1 "$empty");  do bar="${bar}░"; done
  ctx_bar="[${bar}] ${pct}%"
fi

# --- Dracula-style prompt segment: dir + git branch -------------------------
CYAN=$'\033[36m'
BLUE=$'\033[34m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'

cwd=$(echo "$input" | jq -r '.cwd // empty')
dir_name=""
if [ -n "$cwd" ]; then
  dir_name=$(basename "$cwd")
fi

git_segment=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  branch=$(git --no-optional-locks -C "$cwd" symbolic-ref --quiet --short HEAD 2>/dev/null \
           || git --no-optional-locks -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    git_dirty=$(git --no-optional-locks -C "$cwd" status --porcelain 2>/dev/null)
    if [ -n "$git_dirty" ]; then
      git_segment="${CYAN}(${branch}${YELLOW} ✗"$'\033[36m'")"
    else
      git_segment="${CYAN}(${branch}${GREEN} ✓"$'\033[36m'")"
    fi
  fi
fi

# --- Assemble output: grey everywhere, white+bold for dollar values ----------
GREY=$'\033[90m'
WB=$'\033[1;37m'
RST=$'\033[0m'

parts=()
[ -n "$dir_name" ]     && parts+=("${BLUE}${dir_name}${RST} ${git_segment}${RST}")
[ -n "$last_cost" ]    && parts+=("${GREY}Last query: ${WB}${last_cost}${GREY};")
[ -n "$session_cost" ] && parts+=("${GREY}This session: ${WB}${session_cost}${GREY};")
[ -n "$today_cost" ]   && parts+=("${GREY}Today: ${WB}${today_cost}${GREY};")
[ -n "$week_cost" ]    && parts+=("${GREY}This week: ${WB}${week_cost}${GREY};")
[ -n "$ctx_bar" ]      && parts+=("${GREY}Context window: ${ctx_bar};")

result="${parts[0]}"
for part in "${parts[@]:1}"; do
  result="${result}  ${part}"
done

printf "%s%s" "$result" "$RST"
