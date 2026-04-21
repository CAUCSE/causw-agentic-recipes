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
      - 파일 특정 라인에 코멘트하기: gh api \
          repos/{org}/{repository}/pulls/{prNumber}/comments \
          --raw-field body='[P3]\n이 줄의 처리는 조금 더 안전하게 작성할 수 있을 것 같습니다.'\
          -f commit_id=$(git rev-parse HEAD) \
          -f path='src/foo/bar.js' \
          -F line=42 \
          -F side=RIGHT
      - PR 브랜치 checkout: gh pr checkout {pr_url}
  - gh 명령 실행 시 author는 가져오면 안 됩니다.
  - 코멘트는 정중한 말투를 사용하고, 단정적인 표현은 피합니다. 예: “~처럼 보입니다”, “~일 수 있습니다”, “~라고 생각합니다”