$jdtlsTargetRepo = "$env:HOME\vimfiles\coc\extensions\coc-java-data\server"
$jarFile = Get-ChildItem $jdtlsTargetRepo\plugins | Where-Object Name -Match org.eclipse.equinox.launcher_.*

# JDK9+
# java `
#   '-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=1044' `
#   '-Declipse.application=org.eclipse.jdt.ls.core.id2' `
#   '-Dosgi.bundles.defaultStartLevel=4' `
#   '-Declipse.product=org.eclipse.jdt.ls.core.product' `
#   '-Dlog.protocol=true' `
#   '-Dlog.level=ALL' `
#   '-Dsyntaxserver=true' `
#   '-noverify' `
#   '-Xmx4G' `
#   '-jar' "$($jarFile.FullName)" `
#   '-configuration' "$jdtlsTargetRepo\config_win" `
#   '-data' "$env:APPDATA\eclipse" `
#   '--add-modules=ALL-SYSTEM' `
#   '--add-opens java.base/java.util=ALL-UNNAMED' `
#   '--add-opens java.base/java.lang=ALL-UNNAMED'

java `
  '-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=1044' `
  '-Declipse.application=org.eclipse.jdt.ls.core.id1' `
  '-Dosgi.bundles.defaultStartLevel=4' `
  '-Declipse.product=org.eclipse.jdt.ls.core.product' `
  '-Dlog.level=ALL' `
  '-Dsyntaxserver=true' `
  '-noverify' `
  '-Xmx4G' `
  '-jar' "$($jarFile.FullName)" `
  '-configuration' "$jdtlsTargetRepo\config_win" `
  '-data' "$env:APPDATA\eclipse" `
