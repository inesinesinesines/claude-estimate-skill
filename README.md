# Claude Estimate Skill

Claude Code의 작업 소요 시간을 측정하고 예측하는 스킬입니다.

## 기능

- **자동 타이밍 수집**: 모든 도구 호출과 응답 시간을 자동으로 기록
- **시간 예측**: 축적된 데이터를 기반으로 새 작업의 소요 시간 예측
- **통계 분석**: 도구별 실행 시간, 사고 시간 분포 등 상세 통계 제공

## 작동 원리

```
사용자 입력 → [prompt_start 기록]
  → Claude 사고 + 출력 생성
  → [pre_tool 기록] → 도구 실행 → [post_tool 기록]
  → Claude 사고 + 출력 생성
  → [response_end 기록]
```

Claude Code의 **hooks** 기능을 활용하여 `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop` 이벤트마다 타임스탬프를 기록합니다.

## 설치

```bash
git clone https://github.com/YOUR_USERNAME/claude-estimate-skill.git
cd claude-estimate-skill
bash install.sh
```

### 기존 settings.json이 있는 경우

이미 `~/.claude/settings.json`에 다른 훅이 설정되어 있다면, `--force` 옵션으로 자동 병합합니다 (Node.js 필요):

```bash
bash install.sh --force
```

또는 `settings-template.json`의 hooks 섹션을 수동으로 병합하세요.

## 사용법

Claude Code에서:

```
/estimate                          # 축적된 타이밍 통계 보기
/estimate HTML 리포트 작성해줘       # 작업 소요 시간 예측
```

## 설치되는 파일

| 파일 | 위치 | 역할 |
|------|------|------|
| `SKILL.md` | `~/.claude/skills/estimate/` | 스킬 프롬프트 정의 |
| `timing.sh` | `~/.claude/scripts/` | 이벤트 훅 스크립트 (타이밍 기록) |
| `timing-stats.sh` | `~/.claude/scripts/` | 통계 출력 스크립트 |

타이밍 데이터는 `~/.claude/timing/timing.log`에 저장됩니다.

## 삭제

```bash
bash uninstall.sh
```

## 요구사항

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- Bash (Git Bash on Windows)
- Node.js (자동 병합 사용 시, 선택사항)

## 예측 정확도

20~30회 이상의 도구 호출 데이터가 축적되면 의미 있는 예측이 가능합니다. 데이터가 많을수록 정확도가 올라갑니다.

### 예측에 영향을 주는 요인

| 요인 | 영향도 |
|------|--------|
| 모델 (Opus/Sonnet/Haiku) | 큼 (2배 차이) |
| 컨텍스트 길이 | 큼 (긴 대화 시 느려짐) |
| 서버 부하 | 중간 |
| 출력 언어 (한/영) | 중간 (~30%) |

## 라이선스

MIT
