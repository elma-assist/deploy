# Production operations

The server syncs only `github.com/elma-assist/deploy`. Application source code is
not cloned. `/opt/elma/deploy` follows `main` for tag discovery, while the active
stack runs from the immutable archive `/opt/elma/releases/<version>`.

## Release

1. Publish and verify application images in `elma-assist/workspace`.
2. Put their exact version in `release.env`.
3. Commit the deployment configuration to `main`.
4. Create an annotated semantic-version tag and publish a stable GitHub Release.
5. The release workflow deploys that exact tag. Draft and prerelease entries are
   ignored by the manual latest-release lookup.

Tags matching `v*` must be protected against update and deletion in GitHub.
Never use mutable `latest` image tags.

## Manual deployment and rollback

```sh
sudo -u deploy /usr/local/sbin/elma-deploy-latest
sudo -u deploy /usr/local/sbin/elma-deploy-latest v0.1.0
cat /opt/elma/deployed-version
```

The first command deploys GitHub's latest stable Release. The second deploys or
rolls back to one explicit deployment version. Database migrations are forward
only; restore the matching backup when an application rollback is incompatible
with the current schema.

## Persistent state

- `/opt/elma/shared/runtime.env`: provider keys and application secrets.
- `/opt/elma/shared/livekit.yaml`: LiveKit secrets and network configuration.
- `/opt/elma/shared/s3.json`: SeaweedFS credentials.
- `/opt/elma/backups`: database and document backups.
- Docker volumes: PostgreSQL, documents and Let's Encrypt certificates.

Back up manually with `/opt/elma/current/scripts/backup.sh`. The systemd timer
runs it nightly. Backups currently remain on the same server and must eventually
be copied to independent storage.
