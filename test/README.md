# Tests

## Automation Tests

Validates all README script automation examples work correctly.

```bash
# Run with bash
./test/automation/run_tests.sh

# Or run as AI script (meta-test using --permission-mode bypassPermissions)
./test/automation/run_tests.md
```

**Tests cover:**
- Shebang execution (`#!/usr/bin/env ai` and legacy `#!/usr/bin/env claude-run`)
- Stdin piping and `--stdin-position` flag
- Shebang stripping before stdin prepend (security)
- Pipeline chaining
- Shell script integration
- Git log piping

Output is written to `test/automation/output/` (gitignored).
