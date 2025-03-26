# 👨‍💻 Developer Guide – WP Docker

Welcome to the WP Docker developer space! This document is intended to help you understand the development workflow, contribution process, and best practices for working with this project.

---

## 🚀 Project Overview

**WP Docker** is a modular and extensible LEMP-based WordPress management system using Docker. It supports managing multiple isolated WordPress sites with intuitive CLI menus.

---

## 🧱 Development Structure

```
src/
├── main.sh                      # Main entry script
├── shared/
│   ├── scripts/functions/       # Modular Bash functions grouped by features
│   ├── templates/               # Template files for site creation (nginx, docker-compose, etc.)
│   └── config/                  # Global config.sh
└── webserver/nginx/             # NGINX Proxy & global config
```

---

## 👨‍🔧 Local Development Tips

### 🔁 Symlink project for testing:
To simulate installation without re-running `install.sh` every time:
```bash
sudo rm -rf /opt/wp-docker
sudo ln -s ~/wp-docker-lemp/src /opt/wp-docker
```

This allows you to run:
```bash
wpdocker   # Runs /opt/wp-docker/main.sh
```

### 🧪 Test Scripts
You can write `.bats` tests under `tests/` to test your Bash logic.

---

## 🔄 Updating Template Files

If you change any of the following files:
- `src/shared/templates/docker-compose.yml.template`
- `src/shared/templates/nginx-proxy.conf.template`

You must **bump the template version** by updating:
- `src/shared/templates/.template_version`
- `src/shared/templates/TEMPLATE_CHANGELOG.md`

### ✅ Easy way (recommended):
Run the helper script:
```bash
bash src/shared/scripts/tools/template_bump_version.sh
```

It will:
- Ask for the new version
- Prompt for a changelog message
- Update `.template_version`
- Append a timestamped changelog entry

---

## 🤖 Automatic Template Versioning (CI/CD)

If you forget to bump the template version manually — no worries!

### ✔ GitHub Actions will:
- Detect if any file under `src/shared/templates/` is changed
- Auto-run `template_bump_version.sh --auto`
- Automatically bump version and commit back to the same branch

### 🔧 Triggered by:
```yaml
on:
  push:
    paths:
      - 'src/shared/templates/**'
  pull_request:
    paths:
      - 'src/shared/templates/**'
```

> ⚠️ Make sure you open a **Pull Request into `main`** when editing templates. CI will handle the rest.

---

## 🏷 Releasing

Once your changes are merged into `main`, you can create a Git tag:
```bash
git tag v1.0.7-beta
git push origin v1.0.7-beta
```

GitHub Actions will trigger `release.yml` to:
- Build the release `.zip`
- Include version info and updated templates

---

## ✅ Summary

| Task | How |
|------|-----|
| Test code locally | Symlink `/opt/wp-docker` to `src/` |
| Update template version | Run `template_bump_version.sh` |
| Forgot to bump template? | GitHub Action will auto-bump it for you 😎 |
| Ready to release | Tag a version on `main` branch |

---

Happy hacking! 🧠🔥

