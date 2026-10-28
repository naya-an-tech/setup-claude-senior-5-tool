---
description: Claude Code 시니어 도구 5종(Agent Skills, Context7, Graphify, 21st MCP, Strix) 설치
argument-hint: "[--only ids] [--skip ids]  ids: agent-skills,context7,graphify,21st,strix"
allowed-tools: Bash, PowerShell
---

Claude Code를 시니어 개발자처럼 만드는 도구 5종을 이 컴퓨터에 설치한다.
설치 스크립트: https://github.com/naya-an-tech/setup-claude-senior-5-tool

사용자 인자: `$ARGUMENTS` (비어 있으면 5종 전부 설치)

## 진행 순서

1. **OS 판별**: 셸 환경으로 macOS / Linux / Windows 중 무엇인지 확인한다.

2. **API 키 확인**: 스크립트가 키를 대화형으로 물을 수 없으니(비대화형 셸) 먼저 사용자에게 한 번에 묻는다.
   - `CONTEXT7_API_KEY` — 선택. https://context7.com/dashboard
   - `API_KEY_21ST` — 21st MCP 설치에 필요. https://21st.dev/mcp (무료). 없으면 21st 는 건너뛴다.
   - 이미 환경 변수에 있으면 묻지 않는다. 사용자가 "없음/건너뛰기"라고 하면 그대로 진행한다.
   - `--only` 로 해당 도구가 빠진 경우 그 키는 묻지 않는다.

3. **설치 실행** — 받은 키는 환경 변수로만 넘기고, 응답 본문에 키 값을 다시 출력하지 않는다.

   macOS / Linux:
   ```bash
   CONTEXT7_API_KEY="<키 또는 빈 값>" API_KEY_21ST="<키 또는 빈 값>" \
     bash -c "$(curl -fsSL https://raw.githubusercontent.com/naya-an-tech/setup-claude-senior-5-tool/main/install.sh)" -- --yes $ARGUMENTS
   ```

   Windows (PowerShell):
   ```powershell
   $env:CONTEXT7_API_KEY = "<키 또는 빈 값>"; $env:API_KEY_21ST = "<키 또는 빈 값>"
   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/naya-an-tech/setup-claude-senior-5-tool/main/install.ps1))) -Yes <-Only / -Skip 인자>
   ```
   Windows에서 Bash 도구(Git Bash)만 쓸 수 있으면 `powershell -NoProfile -ExecutionPolicy Bypass -Command "..."` 로 위 PowerShell 명령을 감싸 실행한다.
   `$ARGUMENTS` 의 `--only a,b` / `--skip a,b` 는 PowerShell 에서 `-Only a,b` / `-Skip a,b` 로 바꿔 넘긴다.

   Strix 설치는 Docker 이미지를 받느라 수 분 걸릴 수 있으니 타임아웃을 넉넉히(10분) 잡는다.

4. **검증**: `claude mcp list` 와 `claude plugin list` 로 context7 / 21st / agent-skills 가 보이는지, `graphify --version`, `strix --version` 이 동작하는지 확인한다.

5. **보고**: 도구별 결과(설치됨 / 건너뜀 / 실패와 원인)를 표로 정리하고 다음을 안내한다.
   - 새 MCP 서버·플러그인·스킬은 **Claude Code 를 재시작해야** 적용된다.
   - Strix 실행 전 `STRIX_LLM`(예: `anthropic/claude-sonnet-5-5`)과 `LLM_API_KEY` 설정, Docker 실행이 필요하다.
   - Graphify 는 프로젝트에서 `/graphify .` 로 시작한다.
