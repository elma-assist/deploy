#!/usr/bin/env bash
set -Eeuo pipefail
umask 077
root=/opt/elma
release=${1:-$(readlink -f "$root/current")}
# shellcheck disable=SC1091
source "$release/release.env"
: "${IMAGE_TAG:?Missing IMAGE_TAG}"
export IMAGE_TAG ELMA_SHARED_DIR="$root/shared"
target="$root/backups/$(date -u +%Y%m%d-%H%M%S)"
mkdir -p "$target"
compose=(docker compose --env-file "$ELMA_SHARED_DIR/runtime.env" -f "$release/compose.yaml")
"${compose[@]}" exec -T postgres pg_dump -U elma -d elma -Fc > "$target/database.dump.partial"
mv "$target/database.dump.partial" "$target/database.dump"
"${compose[@]}" exec -T api python -m app.backup > "$target/documents.zip.partial"
mv "$target/documents.zip.partial" "$target/documents.zip"
if [[ -f "$root/deployed-version" ]]; then
  cp "$root/deployed-version" "$target/deployed-version"
else
  printf 'DEPLOY_VERSION=legacy\n' > "$target/deployed-version"
fi
echo "Backup created: $target"
