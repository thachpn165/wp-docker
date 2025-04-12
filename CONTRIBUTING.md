# 🤝 Contributing Guide – WP Docker

Thanks for your interest in contributing to **WP Docker**! We welcome all kinds of contributions — from fixing bugs and improving documentation to adding features and refactoring code.

---

## 📋 Table of Contents

- [Development Setup](#development-setup)
- [Workflow](#workflow)
- [Branching Strategy](#branching-strategy)
- [Pull Request Rules](#pull-request-rules)
- [Template Changes & Versioning](#template-changes--versioning)
- [Code Style](#code-style)
- [Reporting Issues](#reporting-issues)

---

## 🧱 Development Setup

- Clone the repo:

  ```bash
  git clone https://github.com/thachpn165/wp-docker.git
  cd wp-docker
  ```

- Run the project using symlink for development:

  ```bash
  cd wp-docker
  bash src/install.sh
  sudo rm -rf /opt/wp-docker
  sudo ln -s ~/wp-docker/src /opt/wp-docker
  wpdocker  # to launch the main menu
  ```

- Test `.bats` files can be placed under `tests/`

### DEBUG_MODE

To enable detailed logging, edit the `src/shared/config/config.sh` file and set the `DEBUG_MODE` variable to `true`.

---

## 🔄 Workflow

We follow a **Pull Request (PR)** based development process.

- Create a feature/fix branch:

  ```bash
  git checkout -b feature/my-feature
  ```

- Commit your changes with clear messages.
- Open a PR to the `main` branch.
- Ensure CI passes before merging.

---

## 🌱 Branching Strategy

| Branch      | Purpose                         |
|-------------|----------------------------------|
| `main`      | Production-ready & release tags |
| `dev`       | Development integration branch  |
| `feature/*` | Individual features/bugfixes    |

> 🔐 `main` is protected. You cannot push directly to it.
> All changes must go through PR and review.

---

## ${CHECKMARK} Pull Request Rules

- Follow the branching strategy above
- PRs that change templates must be bumped via version script (see below)
- Write clear titles and descriptions
- Squash commits if possible before merging

---

## 🔧 Template Changes & Versioning

If you modify any template file under:

```bash
src/shared/templates/
```

You **must bump the template version**.

### ${CHECKMARK} Manual Bump (Recommended):

```bash
bash src/shared/scripts/tools/template_bump_version.sh
```

This will:

- Ask for new version (e.g. 1.0.7)
- Prompt for changelog message
- Update `.template_version`
- Append to `TEMPLATE_CHANGELOG.md`

### 🤖 Automatic Bump via CI

If you forget, GitHub Actions will auto-bump it for you:

- Watches changes under `src/shared/templates/**`
- Runs the same bump script in `--auto` mode
- Commits version + changelog back into your branch

---

## 🧼 Code Style

- Bash scripts must be POSIX-compliant as much as possible
- Use `shellcheck` to lint scripts before committing
- Use `bats-core` for testing reusable Bash functions
- Keep functions small and composable under `shared/scripts/functions/`

---

## 🐞 Reporting Issues

- Use [GitHub Issues](https://github.com/thachpn165/wp-docker/issues)
- Include clear steps to reproduce
- Provide screenshots or logs if applicable
- Suggest fixes if possible 🙌

---

Thank you for making WP Docker better! 🙏
