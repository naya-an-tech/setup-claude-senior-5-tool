# setup-claude-senior-5-tool

Claude Code를 **시니어 개발자처럼** 일하게 만드는 오픈소스 도구 5종을 한 번에 설치합니다.
macOS · Linux(Ubuntu) · Windows를 지원합니다.

| # | 도구 | 하는 일 | 설치 방식 |
|---|------|---------|-----------|
| 1 | [Agent Skills](https://github.com/addyosmani/agent-skills) | Addy Osmani(전 Google 디렉터)의 스킬 모음. 기획→구현→리뷰→배포 단계마다 맞는 스킬이 자동으로 켜짐 | Claude Code 플러그인 |
| 2 | [Context7](https://github.com/upstash/context7) | 지금 쓰는 라이브러리의 **최신 문서**를 Claude에 넣어 옛날 문법으로 짜는 일을 줄임 | MCP 서버 (HTTP) |
| 3 | [Graphify](https://github.com/safishamsi/graphify) | 프로젝트 전체를 **지식 그래프**로 엮어 같은 파일을 반복해서 읽느라 토큰을 쓰지 않게 함 | `uv tool` + Claude 스킬 |
| 4 | [21st MCP](https://21st.dev/mcp) | 1만 개가 넘는 **UI 컴포넌트**를 검색해 프로젝트에 바로 넣음 | MCP 서버 (HTTP, API 키 필요) |
| 5 | [Strix](https://github.com/usestrix/strix) | 해커처럼 내 앱을 직접 공격해 **보안 취약점**과 수정 방법을 찾아줌 | CLI + Claude 스킬 |

---

## 빠른 설치

### 방법 A. 터미널 한 줄 설치

**macOS / Linux (Ubuntu)**

```bash
curl -fsSL https://raw.githubusercontent.com/naya-an-tech/setup-claude-senior-5-tool/main/install.sh | bash
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/naya-an-tech/setup-claude-senior-5-tool/main/install.ps1 | iex
```

설치 중 API 키를 묻습니다. Enter를 누르면 건너뜁니다.

- `CONTEXT7_API_KEY`: 선택. 키가 있으면 사용량 한도가 올라갑니다. → https://context7.com/dashboard
- `API_KEY_21ST`: 21st MCP에 필요합니다(무료). 없으면 21st만 건너뜁니다. → https://21st.dev/mcp

설치가 끝나면 **Claude Code를 다시 시작**하세요.

### 방법 B. Claude Code 안에서 명령어로 설치

이 저장소는 Claude Code 플러그인 마켓플레이스이기도 합니다. Claude Code 안에서:

```
/plugin marketplace add naya-an-tech/setup-claude-senior-5-tool
/plugin install senior-5-tool@naya-an-tech
```

그 뒤 아래 명령을 입력하면 Claude가 OS를 판별하고 필요한 키를 물은 다음 설치하고 검증까지 합니다.

```
/senior-5-tool:setup
/senior-5-tool:setup --only context7,graphify
```

> 플러그인 없이 커맨드만 쓰고 싶다면 파일 하나만 복사해도 됩니다. 이 경우 명령은 `/setup-senior-tools` 입니다.
>
> ```bash
> # macOS / Linux
> mkdir -p ~/.claude/commands && curl -fsSL https://raw.githubusercontent.com/naya-an-tech/setup-claude-senior-5-tool/main/plugins/senior-5-tool/commands/setup.md -o ~/.claude/commands/setup-senior-tools.md
> ```
> ```powershell
> # Windows
> New-Item -ItemType Directory -Force "$HOME\.claude\commands" | Out-Null; irm https://raw.githubusercontent.com/naya-an-tech/setup-claude-senior-5-tool/main/plugins/senior-5-tool/commands/setup.md -OutFile "$HOME\.claude\commands\setup-senior-tools.md"
> ```

---

## 옵션

일부만 설치하거나 키를 미리 넘길 수 있습니다. 도구 ID는 `agent-skills`, `context7`, `graphify`, `21st`, `strix` 입니다.

**macOS / Linux**

```bash
# 원하는 것만 설치
curl -fsSL https://raw.githubusercontent.com/naya-an-tech/setup-claude-senior-5-tool/main/install.sh | bash -s -- --only context7,graphify

# 특정 도구 제외 + 키를 환경 변수로 전달 + 질문 없이 진행
export CONTEXT7_API_KEY=ctx7sk-...
export API_KEY_21ST=...
curl -fsSL https://raw.githubusercontent.com/naya-an-tech/setup-claude-senior-5-tool/main/install.sh | bash -s -- --skip strix --yes
```

**Windows (PowerShell)**

```powershell
$env:CONTEXT7_API_KEY = "ctx7sk-..."
$env:API_KEY_21ST = "..."
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/naya-an-tech/setup-claude-senior-5-tool/main/install.ps1))) -Only context7,21st -Yes
```

| bash | PowerShell | 설명 |
|------|-----------|------|
| `--only a,b` | `-Only a,b` | 지정한 도구만 설치 |
| `--skip a,b` | `-Skip a,b` | 지정한 도구 제외 |
| `--yes` | `-Yes` | 키를 묻지 않음 (환경 변수에 없으면 해당 키는 비워 둠) |

`SENIOR_TOOLS_ONLY` / `SENIOR_TOOLS_SKIP` 환경 변수로도 같은 설정을 할 수 있습니다.
스크립트는 여러 번 실행해도 됩니다. MCP 서버는 다시 등록되므로 키를 바꿀 때도 같은 명령을 쓰면 됩니다.

---

## 사전 요구사항

| 항목 | 필요 여부 | 설치 |
|------|-----------|------|
| [Claude Code](https://docs.claude.com/claude-code) | 필수 | mac/Linux: `curl -fsSL https://claude.ai/install.sh \| bash` · Windows: `irm https://claude.ai/install.ps1 \| iex` |
| git | 필수 | mac: `xcode-select --install` · Ubuntu: `sudo apt install git` · Windows: `winget install Git.Git` |
| Node.js 18+ | 권장 | 대체 설치 경로와 Strix 스킬에 사용. `winget install OpenJS.NodeJS.LTS` / `brew install node` |
| [uv](https://docs.astral.sh/uv/) | 자동 설치 | 없으면 스크립트가 설치합니다 (Graphify, Strix용 Python 도구 관리) |
| Docker | Strix 실행 시 | https://docs.docker.com/get-docker/ |

---

## 무엇이 설치되나

| 도구 | macOS / Linux | Windows |
|------|---------------|---------|
| Agent Skills | `claude plugin marketplace add https://github.com/addyosmani/agent-skills.git`<br>`claude plugin install agent-skills@addy-agent-skills --scope user`<br>(실패 시 `npx skills add addyosmani/agent-skills -g -a claude-code -y`) | 같음 |
| Context7 | `claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp [--header "Authorization: Bearer <KEY>"]` | 같음 |
| Graphify | `uv tool install graphifyy` → `graphify install` | `uv tool install graphifyy` → `graphify install --platform windows` |
| 21st MCP | `claude mcp add --scope user --transport http 21st https://21st.dev/api/mcp --header "x-api-key: <KEY>"` | 같음 |
| Strix | `curl -sSL https://strix.ai/install \| bash` (실패 시 `uv tool install strix-agent`)<br>`npx skills add usestrix/strix -g -a claude-code -y` | `uv tool install --python 3.12 strix-agent`<br>`npx skills add usestrix/strix -g -a claude-code -y` |

모든 MCP 서버와 플러그인은 **user scope**로 설치되므로 모든 프로젝트에서 쓸 수 있습니다.
`graphify install`은 `~/.claude/skills/graphify/`에 스킬을 넣고 `~/.claude/CLAUDE.md`에 Graphify 안내를 추가합니다.

---

## 설치 후 사용법

```bash
claude mcp list        # context7, 21st 확인
claude plugin list     # agent-skills 확인
```

- **Agent Skills**: 작업에 맞춰 자동으로 켜집니다. `/spec`, `/plan`, `/build`, `/test`, `/review`, `/ship` 같은 명령도 있습니다. 내장 명령과 이름이 겹치면 `/agent-skills:review`처럼 씁니다.
- **Context7**: 프롬프트에 `use context7`를 붙이거나 CLAUDE.md에 "라이브러리 질문에는 항상 Context7을 사용" 규칙을 넣으세요.
- **Graphify**: 프로젝트 폴더에서 `/graphify .`
- **21st MCP**: "21st에서 가격표 컴포넌트 찾아서 넣어줘"처럼 자연어로 요청합니다.
- **Strix**: LLM 설정 후 실행합니다. **본인 소유이거나 테스트 권한이 있는 대상에만** 사용하세요.
  ```bash
  export STRIX_LLM="anthropic/claude-sonnet-5-5"
  export LLM_API_KEY="sk-ant-..."
  strix --target ./my-app
  ```

---

## 제거

```bash
claude plugin uninstall agent-skills@addy-agent-skills
claude mcp remove context7 --scope user
claude mcp remove 21st --scope user
graphify uninstall; uv tool uninstall graphifyy
uv tool uninstall strix-agent   # uv로 설치한 경우
rm -rf ~/.strix                 # strix.ai 설치 스크립트로 설치한 경우 (mac/Linux)
npx skills remove -g            # skills CLI로 설치한 스킬 정리 (대화형)
```

---

## 문제 해결

- **`git@github.com: Permission denied (publickey)`**: 스크립트는 HTTPS로 마켓플레이스를 추가하지만, 그래도 실패하면 `git config --global url."https://github.com/".insteadOf git@github.com:` 을 실행한 뒤 다시 시도하세요.
- **`graphify: command not found`**: `uv tool update-shell` 실행 후 터미널을 다시 여세요.
- **`strix: command not found` (mac/Linux)**: `export PATH="$HOME/.strix/bin:$PATH"`를 셸 설정에 추가하세요.
- **Windows 실행 정책 오류**: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` 후 다시 실행하세요.
- 설치한 MCP 서버나 스킬이 보이지 않으면 **Claude Code를 재시작**하세요.

---

## 출처

Facebook 릴스 「클로드 코드를 시니어 개발자로 만드는 도구 5개」의 내용을 정리했습니다. 각 도구의 설치 방법은 2026-10-28 기준 공식 README를 따릅니다.
