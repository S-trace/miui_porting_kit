#!/bin/sh
# Files signed with known ceritain key:
MEDIA_FILE="/system/priv-app/MediaProvider.apk"
PLATFORM_FILE="/system/framework/framework-res.apk"
SHARED_FILE="/system/priv-app/ContactsProvider.apk"
TESTKEY_FILE="/system/priv-app/CalendarProvider.apk"
UNSIGNED_FILE="/system/app/TrafficControl.apk"
GOOGLE_FILE="/system/priv-app/Phonesky.apk"
MIUI_FILE="/system/app/MiuiVideo.apk"
FW="$1"

determine_key_hash(){
  file="$1"
  unzip -o ./$file META-INF/CERT.RSA -d /tmp/ > /dev/null 2>/dev/null
  openssl pkcs7 -inform DER -print_certs -in /tmp/META-INF/CERT.RSA 2>/dev/null|md5sum|cut -d ' ' -f 1 
  rm -rf /tmp/META-INF
}

determine_key(){
  file="$1"
  echo "Determining key for $file"
  unzip -o ./$file META-INF/CERT.RSA -d /tmp/ > /dev/null
  FILE_HASH=$(openssl pkcs7 -inform DER -print_certs -in /tmp/META-INF/CERT.RSA|md5sum|cut -d ' ' -f 1)
  rm -rf /tmp/META-INF
  if [ q$FILE_HASH = q$MEDIA_HASH ]; then
    echo $file >> media.list
    return
  fi
  if [ q$FILE_HASH = q$PLATFORM_HASH ]; then
    echo $file >> platform.list
    return
  fi
  if [ q$FILE_HASH = q$SHARED_HASH ]; then
    echo $file >> shared.list
    return
  fi
  if [ q$FILE_HASH = q$TESTKEY_HASH ]; then
    echo $file >> testkey.list
    return
  fi
  if [ q$FILE_HASH = q$UNSIGNED_HASH ]; then
    echo $file >> unsigned.list
    return
  fi
  if [ q$FILE_HASH = q$GOOGLE_HASH ]; then
    echo $file >> google.list
    return
  fi
  if [ q$FILE_HASH = q$MIUI_HASH ]; then
    echo $file >> miui.list
    return
  fi
  echo $file >> unknown.list
}

cd "$FW"/
MEDIA_HASH=$(determine_key_hash $MEDIA_FILE)
PLATFORM_HASH=$(determine_key_hash $PLATFORM_FILE)
SHARED_HASH=$(determine_key_hash $SHARED_FILE)
TESTKEY_HASH=$(determine_key_hash $TESTKEY_FILE)
GOOGLE_HASH=$(determine_key_hash $GOOGLE_FILE)
MIUI_HASH=$(determine_key_hash $MIUI_FILE)
UNSIGNED_HASH=$(determine_key_hash $UNSIGNED_FILE)
cd -

rm *.list
echo MEDIA:	$MEDIA_HASH 
echo PLATFORM:	$PLATFORM_HASH 
echo SHARED:	$SHARED_HASH 
echo TESTKEY:	$TESTKEY_HASH 
echo GOOGLE:	$GOOGLE_HASH 
echo MIUI:	$MIUI_HASH 
echo UNSIGNED:	$UNSIGNED_HASH
# exit 0
for file in $(find "$FW"/ -iname "*.jar" -or -iname "*.apk"); do 
  determine_key $file
done
