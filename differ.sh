#!/usr/bin/env bash

set -euo pipefail

cd /mnt

declare -a dirs
readarray -d '' dirs < <( find . -mindepth 1 -maxdepth 1 -type d -printf '%f\0' )

echo "blah ${dirs[@]}"

for dirA in "${dirs[@]}"; do
    for dirB in "${dirs[@]}"; do
        if [[ "$dirA" != "$dirB" ]]; then
            echo "diffing $dirA v.s. $dirB"
            { diff --brief --recursive --no-dereference "$dirA" "$dirB" || true ; } > "diff.$dirA.$dirB"
        fi
    done
done
