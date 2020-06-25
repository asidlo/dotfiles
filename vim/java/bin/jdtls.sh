#!/usr/bin/env bash

# How to download eclipse.jdt.ls
# $ mkdir eclipse.jdt.ls && cd $_
# $ curl -L http://download.eclipse.org/jdtls/snapshots/jdt-language-server-latest.tar.gz -O
# $ tar -xzvf jdt-language-server-latest.tar.gz

JDTLS_TARGET_REPO="$HOME/.vim/java/eclipse.jdt.ls"
JDTLS_JAR="$JDTLS_TARGET_REPO/plugins/org.eclipse.equinox.launcher_*.jar"
JAVA_MAJOR_VERSION=$(java -version 2>&1 | head -n 1 | cut -d' ' -f3 | sed -e 's/^"//g' -e 's/"$//g' | cut -d'.' -f1)
DEFAULT_DATA_PARAMS="-data $HOME/.local/share/eclipse"
DEBUG_PARAM_SERVER='-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=1044'

if [ $# -eq 0 ]; then
    OPT_ARGS=$DEFAULT_DATA_PARAMS
else
    OPT_ARGS="$@"
fi

TARGET_OS=$(uname -a)
if [[ $TARGET_OS =~ 'Darwin' ]]; then
    JDTLS_CONFIG='config_mac'
elif [[ $TARGET_OS =~ 'Linux' ]]; then
    JDTLS_CONFIG='config_linux'
fi

if (( $JAVA_MAJOR_VERSION > 8 )); then
    java \
        -Declipse.application=org.eclipse.jdt.ls.core.id1 \
        -Dosgi.bundles.defaultStartLevel=4 \
        -Declipse.product=org.eclipse.jdt.ls.core.product \
        -Dlog.protocol=true \
        -Dlog.level=ALL \
        -Dsyntaxserver=true \
        -noverify \
        -Xmx4G \
        -jar $(echo "$JDTLS_JAR") \
        -configuration "$JDTLS_TARGET_REPO/$JDTLS_CONFIG" \
        --add-modules=ALL-SYSTEM \
        --add-opens java.base/java.util=ALL-UNNAMED \
        --add-opens java.base/java.lang=ALL-UNNAMED \
        $OPT_ARGS
elif (( $JAVA_MAJOR_VERSION == 8 )); then
    java \
        -Declipse.application=org.eclipse.jdt.ls.core.id1 \
        -Dosgi.bundles.defaultStartLevel=4 \
        -Declipse.product=org.eclipse.jdt.ls.core.product \
        -Dlog.level=ALL \
        -Dsyntaxserver=true \
        -noverify \
        -Xmx1G \
        -jar $(echo "$JDTLS_JAR") \
        -configuration "$JDTLS_TARGET_REPO/$JDTLS_CONFIG" \
        $OPT_ARGS
else
    echo "ERROR: JDK 8+ is required to use eclipse.jdt.ls"
    exit 1
fi


