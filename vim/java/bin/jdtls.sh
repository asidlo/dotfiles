#!/usr/bin/env bash
OS=$(uname -a)
if [[ $OS =~ 'Darwin' ]]; then
    CONFIG='config_mac'
elif [[ $OS =~ 'Linux' ]]; then
    CONFIG='config_linux'
fi

JDTLS_TARGET_REPO="$HOME/.vim/java/eclipse.jdt.ls/org.eclipse.jdt.ls.product/target/repository"
JAR="$JDTLS_TARGET_REPO/plugins/org.eclipse.equinox.launcher_*.jar"

java \
  -Declipse.application=org.eclipse.jdt.ls.core.id1 \
  -Dosgi.bundles.defaultStartLevel=4 \
  -Declipse.product=org.eclipse.jdt.ls.core.product \
  -Dlog.protocol=true \
  -Dlog.level=ALL \
  -noverify \
  -Xmx4G \
  -jar $(echo "$JAR") \
  -configuration "$JDTLS_TARGET_REPO/$CONFIG" \
  -data "$HOME/.local/share/eclipse" \
  --add-modules=ALL-SYSTEM \
  --add-opens java.base/java.util=ALL-UNNAMED \
  --add-opens java.base/java.lang=ALL-UNNAMED
