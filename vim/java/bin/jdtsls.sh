#!/usr/bin/env bash

# How to download eclipse.jdt.ls
# $ mkdir eclipse.jdt.ls && cd $_
# $ curl -L http://download.eclipse.org/jdtls/snapshots/jdt-language-server-latest.tar.gz -O
# $ tar -xzvf jdt-language-server-latest.tar.gz

if ! command -v java &> /dev/null; then
    >&2 echo "Java not found in path, unable to execute jar"
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WORKSPACE_HOME=$(dirname $SCRIPT_DIR)

JDTLS_TARGET_REPO="$WORKSPACE_HOME/share/eclipse.jdt.ls"
JDTLS_JAR="$JDTLS_TARGET_REPO/plugins/org.eclipse.equinox.launcher_*.jar"
JAVA_MAJOR_VERSION=$(java -version 2>&1 | head -n 1 | cut -d' ' -f3 | sed -e 's/^"//g' -e 's/"$//g' | cut -d'.' -f1)
DEFAULT_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share/eclipse}"
DEBUGGER_SETTINGS='-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=1045'
# GRADLE_HOME=$(brew --prefix gradle)
OPT_ARGS="$@"

TARGET_OS=$(uname -a)
if [[ $TARGET_OS =~ 'Darwin' ]]; then
    JDTLS_CONFIG='config_mac'
elif [[ $TARGET_OS =~ 'Linux' ]]; then
    JDTLS_CONFIG='config_linux'
fi

if (( $JAVA_MAJOR_VERSION > 8 )); then
    java \
        $DEBUGGER_SETTINGS \
        -Dsyntaxserver=true \
        -Declipse.application=org.eclipse.jdt.ls.core.id1 \
        -Dosgi.bundles.defaultStartLevel=4 \
        -Declipse.product=org.eclipse.jdt.ls.core.product \
        -Dlog.protocol=true \
        -Dlog.level=ALL \
        -noverify \
        -Xmx1G \
        -jar $(echo "$JDTLS_JAR") \
        -configuration "$JDTLS_TARGET_REPO/$JDTLS_CONFIG" \
        --add-modules=ALL-SYSTEM \
        --add-opens java.base/java.util=ALL-UNNAMED \
        --add-opens java.base/java.lang=ALL-UNNAMED \
        -data $DEFAULT_DATA_DIR \
        $OPT_ARGS
elif (( $JAVA_MAJOR_VERSION == 8 )); then
    java \
        $DEBUGGER_SETTINGS \
        -Dsyntaxserver=true \
        -Declipse.application=org.eclipse.jdt.ls.core.id1 \
        -Dosgi.bundles.defaultStartLevel=4 \
        -Declipse.product=org.eclipse.jdt.ls.core.product \
        -Dlog.level=ALL \
        -noverify \
        -Xmx1G \
        -jar $(echo "$JDTLS_JAR") \
        -configuration "$JDTLS_TARGET_REPO/$JDTLS_CONFIG" \
        -data $DEFAULT_DATA_DIR \
        $OPT_ARGS
else
    echo "ERROR: JDK 8+ is required to use eclipse.jdt.ls"
    exit 1
fi


