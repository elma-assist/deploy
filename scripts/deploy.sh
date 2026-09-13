#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

deploy_version=${1:?Deployment version required}
release=$(cd "$(dirname "$0")/.." && pwd)
root=/opt/elma
shared="$root/shared"

[[ "$deploy_version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?$ ]] || exit 2
# release.env is versioned and contains public release metadata only.
# shellcheck disable=SC1091
source "$release/release.env"
: "${IMAGE_TAG:?Set IMAGE_TAG in release.env}"
[[ "$IMAGE_TAG" =~ ^(v[0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?|[a-f0-9]{40})$ ]] || exit 2
export IMAGE_TAG ELMA_SHARED_DIR="$shared"

compose=(docker compose --env-file "$shared/runtime.env" -f "$release/compose.yaml")
"${compose[@]}" config --quiet
"${compose[@]}" pull

if [[ -x "$root/current/scripts/backup.sh" ]]; then
  "$root/current/scripts/backup.sh"
fi

"${compose[@]}" up -d --wait --wait-timeout 240 --remove-orphans
for domain in elma-assist.de rtc.elma-assist.de files.elma-assist.de; do
  curl --silent --show-error --retry 12 --retry-all-errors --retry-delay 5 \
    --resolve "$domain:443:127.0.0.1" "https://$domain/" -o /dev/null
done
for url in https://elma-assist.de/api/health https://elma-assist.de/app https://elma-assist.de/; do
  curl --fail --silent --show-error --retry 12 --retry-all-errors --retry-delay 5 "$url" -o /dev/null
done
curl --fail --silent --show-error --retry 12 --retry-all-errors --retry-delay 5 \
  https://rtc.elma-assist.de/ -o /dev/null

ln -sfn "$release" "$root/current.next"
mv -Tf "$root/current.next" "$root/current"
{
  printf 'DEPLOY_VERSION=%s\n' "$deploy_version"
  printf 'DEPLOY_COMMIT=%s\n' "$(cat "$release/DEPLOY_COMMIT")"
  printf 'IMAGE_TAG=%s\n' "$IMAGE_TAG"
} > "$root/deployed-version"
printf 'Deployed configuration %s with application %s\n' "$deploy_version" "$IMAGE_TAG"
docker builder prune -f --filter until=168h
