#!/usr/bin/env bash

if ! command -v java &> /dev/null; then
    >&2 echo "Java not found in path, unable to execute jar"
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WORKSPACE_HOME=$(dirname $SCRIPT_DIR)

java -jar "$WORKSPACE_HOME/lib/google-java-format.jar" "$@"
