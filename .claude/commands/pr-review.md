---
allowed-tools: Bash(git:*), Bash(gh:*), Read(*.md)
description: "인수로 지정한 PR을 리뷰합니다."
---

$ARGUMENTS를 리뷰해 주세요.
PR URL이 지정되지 않은 경우 현재 repository의 remote 정보와 current branch를 바탕으로 PR을 특정해 주세요.
또는 지정된 PR의 브랜치와 현재 브랜치가 일치하지 않는 경우 해당 브랜치로 checkout해 주세요.
만약 commit이나 파일 diff가 존재하면 중단해 주세요.

▼구체적인 절차

1. PR 내용과 현재 시점의 코멘트를 gh 커맨드로 가져와, 그 정보를 참고해 전체 개요를 설명한다.
    - 설명 내용: 어떤 배경이나 과제가 있어서 이렇게 변경했는지
2. 아래 항목에 대해 각 파일의 요약문을 표시한다.
    - before/after 수정 diff 해설
    - PR 목적에 비추어 적절한 수정인지 여부
3. 아래 항목에 대해 코드베이스를 확인한다.
    - 코드 스타일이 다른 파일과 동일한지
    - 리뷰 대상 파일에 의존하는 파일에서 변경 때문에 문제가 발생하지 않는지
4. 위 결과를 바탕으로 최종 리뷰 결과와 지적 사항을 표시한다.
5. 지적 사항에 대해 리뷰어가 구현자에게 보낼 코멘트 문장을 아래 조건에 따라 작성한다.
    - 구현자에 대한 존중을 잊지 않되, 문장은 짧고 간결하게 전달한다. 최대 3줄 정도
    - 코멘트는 중요도에 따라 [P1], [P2], [P3], [P4], [P5] 의 머릿말을 붙인다. (P1이 가장 중요)
    - 파일 단위 코멘트를 우선하고, 코멘트를 표시할 위치를 명시한다.
    - 아래와 같은 경우가 발견되면 코멘트를 표시한다.
        - PR 목적에 부합하지 않는 구현
        - 보안 문제 발생
        - 코드 스멜 존재
        - 예상치 못한 부작용이나 기존 기능 파괴
        - API/DB를 불필요하게 호출, 처리 시간 증가, 메모리 누수 유발 요인 포함
    - 아래 케이스별로 섹션을 나눠 코멘트를 출력한다.
        - 수정 또는 확인이 필요한 부분
        - 수정은 필요 없지만 우려되는 부분
    - 테스트 추가 필요 여부는 코드베이스를 참고해 판단한다.

- 주의점
    - .github 폴더는 프로젝트 루트 바로 아래에 있다.
    - PR 정보를 가져올 때는 아래 명령어를 모두 실행해야한다.
        - PR 메타 정보: gh pr view --json title,body,files,url {pr_url}
        - PR 파일 diff: gh pr diff {pr_url}
        - PR 코멘트: gh pr view --comments {pr_url}
        - PR에서 파일 라인에 달린 코멘트 확인: gh api repos/{org}/{repository}/pulls/{prNumber}/comments | jq '.[] | {file: .path, user: .user.login, comment:.body}'
        - 파일 특정 라인에 Pending 상태로 코멘트하기:
          개별 코멘트를 즉시 달지 말고, 모든 리뷰 코멘트를 모아 JSON 파일로 작성한 뒤 Review API를 통해 한 번에 Pending 상태로 등록해야 합니다.

          【중요】GitHub API 라인 코멘트 제약:
          - PR diff에 포함된 파일에만 라인 코멘트를 달 수 있습니다.
          - diff 내 hunk에 포함된 라인(변경된 줄 + context 줄)에만 코멘트 가능합니다.
          - diff에 없는 파일이나 hunk 밖 라인은 반드시 body 코멘트로만 처리해야 합니다.

          【필수 사전 작업】라인 코멘트 작성 전, 아래 명령으로 diff에 포함된 파일·라인 범위를 확인합니다:
            # diff에 포함된 파일 목록 확인
            gh pr diff {pr_url} --name-only

            # 특정 파일의 hunk 범위 확인 (새 파일 기준 라인 번호)
            # @@ -old_start,old_count +new_start,new_count @@ 형식
            gh pr diff {pr_url} | grep -A 200 "diff --git a/{파일경로}" | grep "^@@"

            # 코멘트 대상 라인이 hunk 범위 내에 있는지 검증
            # new_start 이상, new_start+new_count 미만인 라인만 유효

          【페이로드 생성】검증된 라인만 comments 배열에 포함합니다:
            - diff에 포함된 파일 + hunk 내 라인: comments 배열에 추가 (side: "RIGHT" 필수)
            - diff 외 파일 또는 hunk 밖 라인: body 텍스트에만 기재

            페이로드 예시:
            {
              "body": "전체 리뷰 요약. diff 외 파일 지적사항은 여기에 포함.",
              "comments": [
                {
                  "path": "src/foo/bar.java",
                  "line": 42,
                  "side": "RIGHT",
                  "body": "[P2]\n설명 (최대 3줄)"
                }
              ]
            }

            페이로드를 파일로 저장 후 API 호출:
            cat > /tmp/review_payload.json << 'EOF'
            { ...페이로드... }
            EOF
            gh api -X POST repos/{org}/{repository}/pulls/{prNumber}/reviews --input /tmp/review_payload.json

          【422 에러 대응】422 응답 시 comments 배열을 제거하고 body-only로 재시도합니다:
            gh api -X POST repos/{org}/{repository}/pulls/{prNumber}/reviews \
              --field body="리뷰 내용" --field event="COMMENT"

        - (선택) 만약 Pending 상태로 두지 않고, 그룹화된 리뷰로 즉시 제출(Submit)하고 싶다면 JSON 내용에 `"event": "COMMENT"`를 추가하세요.
        - PR 브랜치 checkout: gh pr checkout {pr_url}
    - gh 명령 실행 시 author는 가져오면 안 됩니다.
    - 코멘트는 정중한 말투를 사용하고, 단정적인 표현은 피합니다. 예: “~처럼 보입니다”, “~일 수 있습니다”, “~라고 생각합니다”