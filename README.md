# Elma production deployment

This repository is the versioned source for the production Docker Compose stack
at `elma-assist.de`. It contains no application source code and no secrets.

Each stable GitHub Release pins two things:

- the deployment configuration at that Git tag;
- the application image version in `release.env`.

Publishing a release runs validation and asks the production server to deploy
that exact tag. On the server, `/usr/local/sbin/elma-deploy-latest` can deploy the
latest stable GitHub Release manually. A specific version can be selected with
`sudo -u deploy /usr/local/sbin/elma-deploy-latest v0.1.0`.

Production secrets remain in `/opt/elma/shared`. Persistent database, document
and certificate data remain in Docker volumes. See `docs/operations.md`.
