#!/bin/sh
resign_file(){
  apk="$1"
  appname="$2"
  key="$(grep "/$appname.apk$" media.list platform.list shared.list testkey.list|cut -d . -f 1)"
  if [ ! "q$key" = "q" ]; then
    echo Resigning $apk using $key key
    java -jar tools/signapk.jar -a 4 keys/${key}.x509.pem keys/${key}.pk8 $apk $apk-signed
    mv $apk-signed $apk
  else
    echo Cannot determine signing key for $apk - assuming presigned
  fi
}

resign_file "$1" "$2"