# Commit Message Conventions

## Prefix (Conventional Commits)

Use the project's existing commit message conventions (detect from `git log`).
If no convention is established, use Conventional Commits:

- `feat:` — new feature
- `fix:` — bug fix
- `docs:` — documentation only
- `refactor:` — code restructuring, no behavior change
- `test:` — adding or updating tests
- `chore:` — maintenance, tooling, config

## Format Rules

- **First line**: short summary, under 72 characters
- **Body**: bullet points of key changes
- **Last line**: `Co-Authored-By: Claude <noreply@anthropic.com>`

## HEREDOC Template

Use HEREDOC format for multi-line messages:

```bash
git commit -m "$(cat <<'EOF'
type: short summary

- change 1
- change 2

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```
