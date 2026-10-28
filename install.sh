#!/usr/bin/env bash
# setup-claude-senior-5-tool — macOS / Linux(Ubuntu) installer
#
# Claude Code를 "시니어 개발자"처럼 만드는 오픈소스 도구 5종을 한 번에 설치합니다.
#   1. agent-skills : Addy Osmani의 Agent Skills (기획→배포 단계별 스킬)
#   2. context7     : 최신 라이브러리 문서 MCP
#   3. graphify     : 프로젝트 지식 그래프 (토큰 절약)
#   4. 21st         : 21st MCP (UI 컴포넌트 검색/삽입)
#   5. strix        : AI 펜테스트 에이전트
#
# 사용법:
#   curl -fsSL https://raw.githubusercontent.com/naya-an-tech/setup-claude-senior-5-tool/main/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- --only context7,graphify
#
# 옵션:
#   --only <ids>   지정한 도구만 설치 (쉼표 구분)
#   --skip <ids>   지정한 도구 제외 (쉼표 구분)
#   -y, --yes      키 입력 프롬프트 없이 진행 (키가 없으면 해당 단계는 건너뜀)
#   -h, --help     도움말
#
# 환경 변수:
#   CONTEXT7_API_KEY   (선택) https://context7.com/dashboard
#   API_KEY_21ST       (21st MCP에 필요) https://21st.dev/mcp
#   SENIOR_TOOLS_ONLY / SENIOR_TOOLS_SKIP  — --only / --skip 과 동일

set -u

ALL_TOOLS="agent-skills context7 graphify 21st strix"
ONLY="${SENIOR_TOOLS_ONLY:-}"
SKIP="${SENIOR_TOOLS_SKIP:-}"
ASSUME_YES=0
RESULTS=""

if [ -t 1 ]; then
  C_B=$'\033[1m'; C_G=$'\033[32m'; C_Y=$'\033[33m'; C_R=$'\033[31m'; C_C=$'\033[36m'; C_0=$'\033[0m'
else
  C_B=""; C_G=""; C_Y=""; C_R=""; C_C=""; C_0=""
fi

step() { printf '\n%s==> %s%s\n' "$C_B$C_C" "$1" "$C_0"; }
info() { printf '    %s\n' "$1"; }
ok()   { printf '    %s✔ %s%s\n' "$C_G" "$1" "$C_0"; }
warn() { printf '    %s! %s%s\n' "$C_Y" "$1" "$C_0"; }
err()  { printf '    %s✖ %s%s\n' "$C_R" "$1" "$C_0"; }
have() { command -v "$1" >/dev/null 2>&1; }
record() { RESULTS="${RESULTS}$1|$2|$3"$'\n'; }

usage() {
  cat <<'EOF'
Usage: install.sh [--only <ids>] [--skip <ids>] [-y]

  --only <ids>   지정한 도구만 설치 (쉼표 구분)
  --skip <ids>   지정한 도구 제외 (쉼표 구분)
  -y, --yes      키 입력 프롬프트 없이 진행
  ids: agent-skills, context7, graphify, 21st, strix

  env: CONTEXT7_API_KEY (선택), API_KEY_21ST (21st 필요)
EOF
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    --only) ONLY="${2:-}"; shift 2 ;;
    --only=*) ONLY="${1#*=}"; shift ;;
    --skip) SKIP="${2:-}"; shift 2 ;;
    --skip=*) SKIP="${1#*=}"; shift ;;
    -y|--yes) ASSUME_YES=1; shift ;;
    -h|--help) usage ;;
    *) err "알 수 없는 옵션: $1"; exit 1 ;;
  esac
done

in_list() { case ",$2," in *",$1,"*) return 0 ;; esac; return 1; }

selected() {
  if [ -n "$ONLY" ] && ! in_list "$1" "$ONLY"; then return 1; fi
  if [ -n "$SKIP" ] && in_list "$1" "$SKIP"; then return 1; fi
  return 0
}

# curl | bash 로 실행되면 stdin이 스크립트이므로 /dev/tty 에서 입력을 받는다.
ask_secret() {
  local prompt="$1" reply=""
  if [ "$ASSUME_YES" -eq 1 ] || ! { : </dev/tty; } 2>/dev/null; then
    printf ''; return
  fi
  printf '    %s' "$prompt" >/dev/tty
  IFS= read -r -s reply </dev/tty || true
  printf '\n' >/dev/tty
  printf '%s' "$reply"
}

ensure_path() {
  case ":$PATH:" in *":$1:"*) ;; *) [ -d "$1" ] && export PATH="$1:$PATH" ;; esac
}

ensure_uv() {
  ensure_path "$HOME/.local/bin"
  ensure_path "$HOME/.cargo/bin"
  if have uv; then return 0; fi
  info "uv 가 없어 설치합니다 (https://astral.sh/uv)"
  curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1
  ensure_path "$HOME/.local/bin"
  have uv
}

# 이미 등록된 MCP 서버는 지우고 다시 등록해 키 변경을 반영한다.
add_http_mcp() {
  local name="$1" url="$2"; shift 2
  claude mcp remove "$name" --scope user >/dev/null 2>&1 || true
  claude mcp add --scope user --transport http "$name" "$url" "$@"
}

# ---------------------------------------------------------------------------
# 사전 점검
# ---------------------------------------------------------------------------
OS_NAME="$(uname -s)"
case "$OS_NAME" in
  Darwin|Linux) ;;
  *) err "지원하지 않는 OS: $OS_NAME (Windows는 install.ps1 을 사용하세요)"; exit 1 ;;
esac

printf '%sClaude Code Senior 5 Tools 설치%s  (%s)\n' "$C_B" "$C_0" "$OS_NAME"

step "사전 요구사항 확인"
ensure_path "$HOME/.local/bin"
if ! have claude; then
  err "Claude Code CLI(claude)를 찾을 수 없습니다."
  info "먼저 설치하세요: curl -fsSL https://claude.ai/install.sh | bash"
  exit 1
fi
ok "claude $(claude --version 2>/dev/null | head -n1)"
for bin in git curl; do
  if have "$bin"; then ok "$bin"; else err "$bin 이 필요합니다."; exit 1; fi
done
if have npx; then ok "node $(node --version 2>/dev/null)"; else warn "Node.js(npx)가 없습니다. 일부 대체 설치 경로를 쓸 수 없습니다 → https://nodejs.org"; fi

# ---------------------------------------------------------------------------
# 1. Agent Skills
# ---------------------------------------------------------------------------
install_agent_skills() {
  step "[1/5] Agent Skills (addyosmani/agent-skills)"
  # SSH 키가 없어도 동작하도록 HTTPS URL로 마켓플레이스를 추가한다.
  claude plugin marketplace add https://github.com/addyosmani/agent-skills.git >/dev/null 2>&1 || true
  if claude plugin install agent-skills@addy-agent-skills --scope user; then
    ok "Claude Code 플러그인으로 설치됨"
    record agent-skills OK "plugin agent-skills@addy-agent-skills"
    return
  fi
  warn "플러그인 설치 실패 → skills CLI 로 재시도"
  if have npx && npx -y skills add addyosmani/agent-skills -g -a claude-code -y; then
    ok "skills CLI 로 설치됨 (~/.claude/skills)"
    record agent-skills OK "npx skills add"
  else
    err "설치 실패"
    record agent-skills FAIL "Claude Code 안에서 /plugin marketplace add addyosmani/agent-skills 시도"
  fi
}

# ---------------------------------------------------------------------------
# 2. Context7
# ---------------------------------------------------------------------------
install_context7() {
  step "[2/5] Context7 MCP (upstash/context7)"
  local key="${CONTEXT7_API_KEY:-}"
  if [ -z "$key" ]; then
    info "API 키는 선택입니다(없어도 동작, 키가 있으면 사용량 한도가 높아짐)."
    key="$(ask_secret 'CONTEXT7_API_KEY (Enter로 건너뛰기): ')"
  fi
  if [ -n "$key" ]; then
    add_http_mcp context7 https://mcp.context7.com/mcp --header "Authorization: Bearer $key"
  else
    add_http_mcp context7 https://mcp.context7.com/mcp
  fi
  if [ $? -eq 0 ]; then
    ok "MCP 서버 'context7' 등록 (user scope)"
    record context7 OK "MCP https://mcp.context7.com/mcp"
  else
    err "등록 실패"
    record context7 FAIL "claude mcp add 실패"
  fi
}

# ---------------------------------------------------------------------------
# 3. Graphify
# ---------------------------------------------------------------------------
install_graphify() {
  step "[3/5] Graphify (PyPI: graphifyy)"
  if ! ensure_uv; then
    err "uv 설치 실패"; record graphify FAIL "uv 설치 실패"; return
  fi
  # 공식 패키지명은 graphifyy (y 두 개)
  if uv tool install --upgrade graphifyy >/dev/null 2>&1 || uv tool install graphifyy; then
    ensure_path "$(uv tool dir --bin 2>/dev/null || echo "$HOME/.local/bin")"
    if graphify install; then
      ok "graphify CLI + Claude Code 스킬 등록 (사용: /graphify .)"
      record graphify OK "uv tool graphifyy + graphify install"
      return
    fi
  fi
  err "설치 실패"
  record graphify FAIL "uv tool install graphifyy && graphify install 수동 실행"
}

# ---------------------------------------------------------------------------
# 4. 21st MCP
# ---------------------------------------------------------------------------
install_21st() {
  step "[4/5] 21st MCP (21st.dev)"
  local key="${API_KEY_21ST:-}"
  if [ -z "$key" ]; then
    info "API 키가 필요합니다 → https://21st.dev/mcp (무료)"
    key="$(ask_secret 'API_KEY_21ST (Enter로 건너뛰기): ')"
  fi
  if [ -z "$key" ]; then
    warn "키가 없어 건너뜁니다. 나중에: API_KEY_21ST=... bash install.sh --only 21st"
    record 21st SKIP "API_KEY_21ST 없음"
    return
  fi
  if add_http_mcp 21st https://21st.dev/api/mcp --header "x-api-key: $key"; then
    ok "MCP 서버 '21st' 등록 (user scope)"
    record 21st OK "MCP https://21st.dev/api/mcp"
  else
    err "등록 실패"
    record 21st FAIL "claude mcp add 실패"
  fi
}

# ---------------------------------------------------------------------------
# 5. Strix
# ---------------------------------------------------------------------------
install_strix() {
  step "[5/5] Strix (usestrix/strix)"
  local installer
  installer="$(mktemp)"
  if curl -fsSL https://strix.ai/install -o "$installer" && bash "$installer"; then
    ensure_path "$HOME/.local/bin"
    ensure_path "$HOME/.strix/bin"
    ok "strix CLI 설치됨"
  elif ensure_uv && uv tool install --python 3.12 strix-agent; then
    ok "strix CLI 설치됨 (uv tool)"
  else
    rm -f "$installer"
    err "strix CLI 설치 실패"
    record strix FAIL "curl -sSL https://strix.ai/install | bash 수동 실행"
    return
  fi
  rm -f "$installer"
  # Claude Code 에서 strix 를 부를 수 있도록 공식 스킬도 설치
  if have npx && npx -y skills add usestrix/strix -g -a claude-code -y >/dev/null 2>&1; then
    ok "Strix 스킬 설치됨 (~/.claude/skills)"
  else
    warn "Strix 스킬 설치는 건너뜀 (npx skills add usestrix/strix)"
  fi
  have docker || warn "Strix 는 Docker 가 실행 중이어야 합니다 → https://docs.docker.com/get-docker/"
  info "실행 전 LLM 설정: export STRIX_LLM=\"anthropic/claude-sonnet-5-5\"; export LLM_API_KEY=\"...\""
  record strix OK "strix CLI + skills"
}

for t in $ALL_TOOLS; do
  selected "$t" || continue
  case "$t" in
    agent-skills) install_agent_skills ;;
    context7)     install_context7 ;;
    graphify)     install_graphify ;;
    21st)         install_21st ;;
    strix)        install_strix ;;
  esac
done

# ---------------------------------------------------------------------------
# 결과 요약
# ---------------------------------------------------------------------------
step "결과 요약"
FAILED=0
printf '%s' "$RESULTS" | while IFS='|' read -r name status note; do
  [ -z "$name" ] && continue
  case "$status" in
    OK)   printf '    %s✔%s %-13s %s\n' "$C_G" "$C_0" "$name" "$note" ;;
    SKIP) printf '    %s–%s %-13s %s\n' "$C_Y" "$C_0" "$name" "$note" ;;
    *)    printf '    %s✖%s %-13s %s\n' "$C_R" "$C_0" "$name" "$note" ;;
  esac
done
case "$RESULTS" in *"|FAIL|"*) FAILED=1 ;; esac

printf '\n    Claude Code 를 다시 시작하면 적용됩니다. 확인: claude mcp list / claude plugin list\n'
exit "$FAILED"
