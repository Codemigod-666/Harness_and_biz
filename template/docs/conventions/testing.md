# Conventions: testing (TEST)

Status: Approved (playbook).

| ID | Rule | Enforced |
|----|------|----------|
| TEST-1 | Test names are behaviour sentences ("a failed read on /sources shows the error with a retry") | review |
| TEST-2 | Arrange / act / assert separated by blank lines | review |
| TEST-3 | A bug fix starts with a test that fails before the fix | review |
| TEST-4 | Fakes over mocks; one contract suite runs over every implementation (real, fake, recorded) | review |
| TEST-5 | No sleeps; wait on conditions or inject clocks | lint |
| TEST-6 | E2E against fakes on the worker's own port (`$FLEET_PORT`), never reusing a server another agent started, timezone UTC | config |
| TEST-7 | E2E selects by role and accessible name only | review |
| TEST-8 | Live E2E: one run at a time, a single test worker, against the running stack | config |
| TEST-9 | Specs from data tables where cases repeat (loop over a list of cases) | review |
| TEST-10 | Flaky claims need `--repeat-each=10` evidence either way | review |
| TEST-11 | Verify/screenshot scripts are tooling, not tests; nothing gates on them, and they say so in a README | review |
| TEST-12 | Shared fixtures live in one module per test suite | review |
