#!/usr/bin/env bash

# How to download eclipse.jdt.ls
# $ mkdir eclipse.jdt.ls && cd $_
# $ curl -L http://download.eclipse.org/jdtls/snapshots/jdt-language-server-latest.tar.gz -O
# $ tar -xzvf jdt-language-server-latest.tar.gz

# Note that java 8 stopped being supported as of version: 0.58
# so if using java 8, then youll need to download that version instead
# mkdir eclipse.jdt.ls && cd $_ 
# curl -L http://download.eclipse.org/jdtls/snapshots/jdt-language-server-0.58.0-202007061255.tar.gz -O
# tar -xzvf jdt-language-server-0.58.0-202007061255.tar.gz

if ! command -v java &> /dev/null; then
	>&2 echo "Java not found in path, unable to execute jar"
	exit 1
fi

JDTLS_TARGET_REPO="$HOME/.local/share/nvim/lsp_servers/jdtls"
# JDTLS_TARGET_REPO="/opt/eclipse.jdt.ls"
JDT8LS_TARGET_REPO="/opt/eclipse.jdt.ls.1_8"
JDTLS_JAR="$JDTLS_TARGET_REPO/plugins/org.eclipse.equinox.launcher_*.jar"
JDT8LS_JAR="$JDT8LS_TARGET_REPO/plugins/org.eclipse.equinox.launcher_*.jar"
JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d' ' -f3 | sed -e 's/^"//g' -e 's/"$//g')
JAVA_MAJOR_VERSION=$(echo "$JAVA_VERSION" | cut -d'.' -f1)
DEBUGGER_SETTINGS='-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=1044'

if [ $# -eq 0 ]; then
	DEFAULT_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share/eclipse}"
else
	DEFAULT_DATA_DIR=$1
fi

TARGET_OS=$(uname -a)
if [[ $TARGET_OS =~ 'Darwin' ]]; then
	JDTLS_CONFIG='config_mac'
elif [[ $TARGET_OS =~ 'Linux' ]]; then
	JDTLS_CONFIG='config_linux'
fi

if (( JAVA_MAJOR_VERSION > 8 )); then
	GRADLE_HOME="$HOME/.sdkman/candidates/gradle/current/bin/gradle" java \
		"$DEBUGGER_SETTINGS" \
		"-javaagent:$HOME/.local/lib/lombok.jar" \
		"-Xbootclasspath/a:$HOME/.local/lib/lombok.jar" \
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
		-data "$DEFAULT_DATA_DIR"
elif [[ $(echo "$JAVA_VERSION" | cut -d'.' -f1,2) == "1.8" ]]; then
	GRADLE_HOME="$HOME/.sdkman/candidates/gradle/current/bin/gradle" java \
		"$DEBUGGER_SETTINGS" \
		"-javaagent:$HOME/.local/lib/lombok.jar" \
		"-Xbootclasspath/a:$HOME/.local/lib/lombok.jar" \
		-Declipse.application=org.eclipse.jdt.ls.core.id1 \
		-Dosgi.bundles.defaultStartLevel=4 \
		-Declipse.product=org.eclipse.jdt.ls.core.product \
		-Dlog.level=ALL \
		-noverify \
		-Xmx1G \
		-jar $(echo "$JDT8LS_JAR") \
		-configuration "$JDT8LS_TARGET_REPO/$JDTLS_CONFIG" \
		-data "$DEFAULT_DATA_DIR"
else
	>&2 echo "ERROR: JDK 8+ is required to use eclipse.jdt.ls"
	exit 1
fi


