#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

if [[ ! -e /.dockerenv ]]
then
    echo "You are not inside a docker container!. Aborting."
    exit 1
fi

DATADIR=/var/lib/mysql
RUN_DIR=/run/mysqld
SOCKET="$RUN_DIR/mysqld.sock"
PORT=3306

mkdir -p "$RUN_DIR"
chown -R mysql:mysql "$RUN_DIR" "$DATADIR"

rm -f "$SOCKET"
rm -f "$DATADIR"/*.pid "$DATADIR"/aria_log_control "$DATADIR"/aria_log.*

if [ ! -d "$DATADIR/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mysql_install_db --user=mysql --datadir="$DATADIR" --auth-root-authentication-method=normal
fi

echo "Starting MariaDB..."
exec sudo -u mysql mariadbd \
    --datadir="$DATADIR" \
    --socket="$SOCKET" \
    --port="$PORT" \
    --skip-networking=0 \
    --skip-grant-tables=0 \
    --skip-external-locking &
