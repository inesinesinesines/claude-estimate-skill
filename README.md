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

### 명시적 호출

Claude Code에서:

```
/estimate                          # 축적된 타이밍 통계 보기
/estimate HTML 리포트 작성해줘       # 작업 소요 시간 예측
```

### 자동 인라인 표시 (권장)

프로젝트의 `CLAUDE.md`에 아래를 추가하면, **모든 응답의 첫 줄**에 예상 시간이 자동 표시됩니다:

```markdown
## 작업 시간 예측 자동 표시

**모든 응답의 첫 줄에** 예상 소요 시간을 표시하세요.
구현 작업뿐 아니라 질의응답, 탐색, 설명 등 모든 유형의 요청에 적용합니다.

estimate 스킬(v5)의 공식을 적용합니다:
1. 생성할 출력물의 예상 크기(글자 수)와 유형을 파악
2. 필요한 도구 호출 시퀀스를 나열
3. 판단 시간 분류표(v5)에 따라 각 전환별 시간 차등 적용
4. 사전 작업물 존재 여부 확인 후 할인 적용
5. 환경 보정 적용 (모델 계수 x 컨텍스트 계수 x 언어 계수)

표시 형식 (간결하게 한 줄):
> 예상: ~N분 M초 (출력물 Xs + 도구 Ys + 판단 Zs | 보정: 모델×컨텍스트×언어)
```

이렇게 설정하면 질문을 하든 구현을 요청하든, 응답 시작 시 한 줄로 예상 시간이 표시됩니다. 상세 내역이 필요하면 `/estimate`를 호출하세요.

## 실측 캘리브레이션

20회 이상 도구 호출이 쌓이면, 실측 데이터 기반으로 예측 정확도를 높일 수 있습니다:

```bash
bash ~/.claude/scripts/calibrate.sh
```

이 명령은 `~/.claude/timing/calibration.json`을 생성합니다:

```json
{
  "tool_avg": {
    "Read": { "avg_ms": 480, "count": 150 },
    "Bash": { "avg_ms": 2300, "count": 89 }
  },
  "gap": {
    "same_tool": { "avg_ms": 5200, "count": 80 },
    "diff_tool": { "avg_ms": 6800, "count": 120 }
  },
  "response_avg": { "avg_duration_ms": 45000, "avg_tools_per_response": 5.2 }
}
```

`/estimate` 호출 시 calibration.json이 있으면 **SKILL.md의 기본값 대신 실측값을 우선 사용**합니다. 데이터가 20회 미만이면 기본값과 실측값을 가중평균합니다.

환경이 바뀌면 (모델 변경, 새 머신 등) 다시 `calibrate.sh`를 실행하면 됩니다.

## 설치되는 파일

| 파일 | 위치 | 역할 |
|------|------|------|
| `SKILL.md` | `~/.claude/skills/estimate/` | 스킬 프롬프트 정의 |
| `timing.sh` | `~/.claude/scripts/` | 이벤트 훅 스크립트 (타이밍 기록) |
| `timing-stats.sh` | `~/.claude/scripts/` | 통계 출력 스크립트 |
| `calibrate.sh` | `~/.claude/scripts/` | 실측 데이터 → calibration.json 변환 |

타이밍 데이터는 `~/.claude/timing/timing.log`에, 캘리브레이션 결과는 `~/.claude/timing/calibration.json`에 저장됩니다.

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
