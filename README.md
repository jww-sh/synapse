> [!NOTE]
> **This is a community-maintained deployment template, not an official Upsun-supported project.**
> It is provided *as is* and may not receive timely updates or bug fixes.
> You are welcome to fork and modify it for your own use.

# Synapse (Matrix Homeserver) for Upsun

This template deploys **[Synapse](https://github.com/element-hq/synapse)** — the reference Matrix homeserver — on [Upsun](https://www.upsun.com). The Synapse package is installed via pip during the build step. A PostgreSQL database comes pre-configured.

Matrix is an open standard for decentralized, real-time communication. Synapse is the most widely used Matrix homeserver implementation.

## Features

- Synapse (latest, pinned in `synapse_version`)
- Python 3.12
- PostgreSQL 16
- Auto-generated signing key and secrets
- Admin user created on first deploy

## Structure

| File | Purpose |
|---|---|
| `.upsun/config.yaml` | Upsun app, service, route, and mount definitions |
| `build.sh` | Installs Synapse via pip |
| `deploy.sh` | Generates secrets, signing key, and `homeserver.yaml` |
| `postdeploy.sh` | Registers the initial admin user via `register_new_matrix_user` |
| `.environment` | Sets admin username/email used during first deploy |
| `synapse_version` | Pinned Synapse version |

## Deploying

```bash
upsun project:create
git push upsun main
```

## Post-deploy

After the first deploy, retrieve the admin password via SSH:

```bash
upsun ssh -- cat /app/data/admin_credentials
```

Then log in with a Matrix client (e.g. [Element](https://element.io)) using:

- **Homeserver URL**: your Upsun domain
- **Username**: `@admin:<your-domain>`
- **Password**: retrieved above

> **Change your password immediately after first login.**

## Updating Synapse

Edit `synapse_version`, commit, and push:

```bash
echo "1.150.0" > synapse_version
git add synapse_version && git commit -m "Update Synapse to 1.150.0"
git push upsun main
```

## Customization

Override any `homeserver.yaml` setting via environment variables — see the
[Synapse configuration docs](https://element-hq.github.io/synapse/latest/usage/configuration/config_documentation.html).

To enable user registration:

```bash
upsun variable:set env:SYNAPSE_ENABLE_REGISTRATION true
```

Then add `enable_registration: true` to the `homeserver.yaml` block in `deploy.sh`.

## Mounts

| Path | Contents |
|---|---|
| `/app/data/` | `homeserver.yaml`, signing key, secrets, pid, installed flag |
| `/app/media/` | User-uploaded media |

## Federation

Your Matrix server name will be the primary Upsun route domain (e.g. `matrix.example.com`). User IDs will look like `@user:matrix.example.com`.

For federation with other Matrix servers, ensure port 8448 is reachable or configure a
[`.well-known` delegation](https://spec.matrix.org/latest/server-server-api/#server-discovery).
