#!/usr/bin/env bash

if ! command -v java &> /dev/null; then
    >&2 echo "Java not found in path, unable to execute jar"
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WORKSPACE_HOME=$(dirname $SCRIPT_DIR)

# https://github.com/google/google-java-format/issues/538
java \
	--add-exports jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED \
	--add-exports jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED \
	--add-exports jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED \
	--add-exports jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED \
	--add-exports jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED \
	-jar "$WORKSPACE_HOME/lib/google-java-format.jar" "$@"
