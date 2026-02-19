## Git Rules

- **Commit Format:** Conventional commits — `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`, `test:`, `perf:`, `ci:`
- **Commit Scope:** Optional — `feat(auth):`, `fix(api):`, `chore(deps):`
- **Commit Message:** Imperative mood, lowercase, no period — `feat: add user authentication`
- **Branch Naming:** `feature/`, `fix/`, `chore/` prefixes — e.g. `feature/user-auth`, `fix/login-redirect`
- **Never** force push to main/master without explicit user confirmation
- **Always** pull before push to avoid conflicts
- **Co-author:** All Claude commits include `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>`
- **Atomic Commits:** Each commit should be a single logical change
- **No WIP Commits:** Don't commit work-in-progress to main — use branches or stash
- **Max Files:** If committing >20 files, review the change set first for unintended changes
