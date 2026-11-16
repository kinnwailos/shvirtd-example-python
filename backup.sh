#!/usr/bin/env bash
# Backup MySQL with schnitzler/mysqldump.
# Credentials are read from the project .env at runtime and are not stored in this script.
#
# Cron, every minute (install on the VM, do not commit passwords):
#   * * * * * /opt/shvirtd-example-python/backup.sh >> /var/log/mysql-backup.log 2>&1
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ENV_FILE:-${SCRIPT_DIR}/.env}"
BACKUP_DIR="${BACKUP_DIR:-/opt/backup}"
NETWORK="${NETWORK:-backend}"
DB_HOST="${DB_HOST:-db}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Env file not found: ${ENV_FILE}" >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is empty}"
: "${MYSQL_DATABASE:?MYSQL_DATABASE is empty}"

mkdir -p "${BACKUP_DIR}"
stamp="$(date +%Y%m%d_%H%M%S)"
filename="${MYSQL_DATABASE}_${stamp}.sql"

# schnitzler/mysqldump ships an old client without caching_sha2_password.
# The compose db service enables mysql_native_password; switch root@% before dump.
docker run --rm \
  --network "${NETWORK}" \
  -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" \
  mysql:8 \
  mysql -h "${DB_HOST}" -uroot -e \
  "ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';"

docker run --rm \
  --network "${NETWORK}" \
  --entrypoint "" \
  -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" \
  -v "${BACKUP_DIR}:/backup" \
  schnitzler/mysqldump \
  mysqldump --opt --single-transaction \
  -h "${DB_HOST}" \
  -uroot \
  --result-file="/backup/${filename}" \
  "${MYSQL_DATABASE}"

echo "Backup written: ${BACKUP_DIR}/${filename}"
