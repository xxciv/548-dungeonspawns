#!/usr/bin/env bash
# Create the auth, characters and world databases for alexkulya/pandaria_5.4.8.
#
# Imports the base dumps from sql/base, then applies world updates in this order:
#   1. the three undated sql/old/world files added after the 2023 base dump
#   2. every dated sql/old/world file (2023-2026 fixes the base dump predates)
#   3. every sql/updates/world file, subfolders included
# and the sql/updates auth/characters files. The project's own docker/initdb skips
# step 1 and 2, which leaves out three years of world fixes.
#
# Usage:
#   export MYSQL_PWD='root-password'          # avoids a password prompt per file
#   MYSQL_ARGS="-u root" ./install_databases.sh /path/to/pandaria_5.4.8
#
# Database names default to auth/characters/world; override with AUTH_DB, CHAR_DB, WORLD_DB.
# The script refuses to touch databases that already exist.
set -euo pipefail

SRC=${1:?usage: install_databases.sh /path/to/pandaria_5.4.8}
SQL="$SRC/sql"
AUTH_DB=${AUTH_DB:-auth}
CHAR_DB=${CHAR_DB:-characters}
WORLD_DB=${WORLD_DB:-world}
read -r -a MYSQL_OPTS <<< "${MYSQL_ARGS:-}"
MYSQL=(mysql "${MYSQL_OPTS[@]}" --max-allowed-packet=1G)

# Known failure: translation fixes for tables this schema does not have. English text is unaffected.
KNOWN_FAILURES="old/world/2026_08_06_21_world_repair_locale_encoding.sql"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
: > "$tmp/failed"

[ -d "$SQL/base" ] || { echo "error: $SQL/base not found" >&2; exit 1; }
command -v unzip >/dev/null || { echo "error: unzip is not installed (apt install unzip)" >&2; exit 1; }

for db in "$AUTH_DB" "$CHAR_DB" "$WORLD_DB"; do
    if [ -n "$("${MYSQL[@]}" -N -e "SHOW DATABASES LIKE '$db'")" ]; then
        echo "error: database '$db' already exists; drop it or choose another name" >&2
        exit 1
    fi
done

# import_base <zip> <database name inside the dump> <target database>
import_base() {
    echo ">>> $3 < ${1#"$SQL"/}"
    "${MYSQL[@]}" -e "CREATE DATABASE \`$3\`"
    unzip -p "$1" | sed -E "/^CREATE DATABASE .*\`$2\`/d; /^USE \`$2\`;/d" | "${MYSQL[@]}" "$3"
}

# apply <database> <file>...
apply() {
    local db=$1 f rel
    shift
    for f in "$@"; do
        rel=${f#"$SQL"/}
        echo "    $db < $rel"
        if ! "${MYSQL[@]}" --force "$db" < "$f" > "$tmp/out" 2>&1 || grep -q '^ERROR' "$tmp/out"; then
            echo "$rel" >> "$tmp/failed"
            grep '^ERROR' "$tmp/out" | head -3 | sed 's/^/      /'
        fi
    done
}

# sorted_sql <dir> [find args...]: every .sql below dir, sorted, NUL-safe for names with spaces or quotes
sorted_sql() {
    local dir=$1
    shift
    [ -d "$dir" ] || return 0
    find "$dir" "$@" -name '*.sql' -print0 | sort -z
}

import_base "$(ls "$SQL"/base/auth_*.zip | head -1)" auth "$AUTH_DB"
import_base "$(ls "$SQL"/base/characters_*.zip | head -1)" characters "$CHAR_DB"
import_base "$(ls "$SQL"/base/world_*.zip | head -1)" world "$WORLD_DB"

echo ">>> world updates"
undated=()
for name in world.quest_texts.sql world.camp_narache.sql world.new_tinkertown.sql; do
    [ -f "$SQL/old/world/$name" ] && undated+=("$SQL/old/world/$name")
done
apply "$WORLD_DB" "${undated[@]}"
mapfile -d '' files < <(sorted_sql "$SQL/old/world" -maxdepth 1 -name '20*')
apply "$WORLD_DB" "${files[@]}"
mapfile -d '' files < <(sorted_sql "$SQL/updates/world")
apply "$WORLD_DB" "${files[@]}"

echo ">>> auth and characters updates"
mapfile -d '' files < <(sorted_sql "$SQL/updates/auth")
apply "$AUTH_DB" "${files[@]}"
mapfile -d '' files < <(sorted_sql "$SQL/updates/characters")
apply "$CHAR_DB" "${files[@]}"

unexpected=$(grep -vxF "$KNOWN_FAILURES" "$tmp/failed" || true)
echo
echo "creatures: $("${MYSQL[@]}" -N -e "SELECT COUNT(*) FROM \`$WORLD_DB\`.creature")," \
     "gameobjects: $("${MYSQL[@]}" -N -e "SELECT COUNT(*) FROM \`$WORLD_DB\`.gameobject")"
if [ -n "$unexpected" ]; then
    echo "These update files failed and need a look:"
    printf '  %s\n' $unexpected
    exit 1
fi
echo "Done. $(grep -cxF "$KNOWN_FAILURES" "$tmp/failed" || true) known translation-only failure(s) can be ignored."
