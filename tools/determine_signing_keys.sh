#!/bin/sh
# Files signed with known ceritain key:
MEDIA_FILE="/system/priv-app/MediaProvider/MediaProvider.apk"
PLATFORM_FILE="/system/framework/framework-res.apk"
SHARED_FILE="/system/priv-app/ContactsProvider/ContactsProvider.apk"
TESTKEY_FILE="/system/priv-app/CalendarProvider/CalendarProvider.apk"
UNSIGNED_FILE="/system/framework/framework.jar"
GOOGLE_FILE="/system/priv-app/Phonesky/Phonesky.apk"
MIUI_FILE="/system/app/MiuiVideo/MiuiVideo.apk"
PATCHROM_FILE="/system/app/Email/Email.apk"
FW="$1"

# Well known serials (CM-13.0 test-keys)
KNOWN_MEDIA_SERIAL="f2b98e6123572c4e"
KNOWN_PLATFORM_SERIAL="b3998086d056cffa"
KNOWN_SHARED_SERIAL="f2a73396bd38767a"
KNOWN_TESTKEY_SERIAL="936eacbe07f201df"
KNOWN_VERITY_SERIAL="970f983909aa8949"

determine_key_serial(){
  file="$1"
  keytool -printcert -jarfile ./$file|grep 'Serial '|cut -d ' ' -f 3
}

determine_key(){
  file="$1"
  echo -n "Determining key for $file... "
  FORCED_KEY=$(grep $file forced_keys|cut -d : -f 2)
  if [ "q$FORCED_KEY" != q ]; then
    echo $file >> "$FORCED_KEY.list"
    echo FORCED $FORCED_KEY
    return
  fi
  if [ q$FILE_SERIAL = q$KNOWN_MEDIA_SERIAL ]; then
    echo $file >> known_media.list
    echo known_media
    return
  fi
  if [ q$FILE_SERIAL = q$KNOWN_PLATFORM_SERIAL ]; then
    echo $file >> known_platform.list
    echo known_platform
    return
  fi
  if [ q$FILE_SERIAL = q$KNOWN_SHARED_SERIAL ]; then
    echo $file >> known_shared.list
    echo known_shared
    return
  fi
  if [ q$FILE_SERIAL = q$KNOWN_TESTKEY_SERIAL ]; then
    echo $file >> known_testkey.list
    echo known_testkey
    return
  fi
  if [ q$FILE_SERIAL = q$KNOWN_VERITY_SERIAL ]; then
    echo $file >> known_verity.list
    echo known_verity
    return
  fi
  FILE_SERIAL="$(determine_key_serial "./$file")"
  if [ q$FILE_SERIAL = q$MEDIA_SERIAL ]; then
    echo $file >> media.list
    echo media
    return
  fi
  if [ q$FILE_SERIAL = q$PLATFORM_SERIAL ]; then
    echo $file >> platform.list
    echo platform
    return
  fi
  if [ q$FILE_SERIAL = q$SHARED_SERIAL ]; then
    echo $file >> shared.list
    echo shared
    return
  fi
  if [ q$FILE_SERIAL = q$TESTKEY_SERIAL ]; then
    echo $file >> testkey.list
    echo testkey
    return
  fi
  if [ q$FILE_SERIAL = q$GOOGLE_SERIAL ]; then
    echo $file >> google.list
    echo google
    return
  fi
  if [ q$FILE_SERIAL = q$MIUI_SERIAL ]; then
    echo $file >> miui.list
    echo miui
    return
  fi
  if [ q$FILE_SERIAL = q$PATCHROM_SERIAL ]; then
    echo $file >> patchrom.list
    echo patchrom
    return
  fi
  if [ q$FILE_SERIAL = q$UNSIGNED_SERIAL ]; then
    echo $file >> unsigned.list
    echo unsigned
    return
  fi
  echo $file >> unknown.list
  echo unknown
}

cd "$FW"/
MEDIA_SERIAL=$(determine_key_serial $MEDIA_FILE)
PLATFORM_SERIAL=$(determine_key_serial $PLATFORM_FILE)
SHARED_SERIAL=$(determine_key_serial $SHARED_FILE)
TESTKEY_SERIAL=$(determine_key_serial $TESTKEY_FILE)
GOOGLE_SERIAL=$(determine_key_serial $GOOGLE_FILE)
MIUI_SERIAL=$(determine_key_serial $MIUI_FILE)
PATCHROM_SERIAL=$(determine_key_serial $PATCHROM_FILE)
UNSIGNED_SERIAL=$(determine_key_serial $UNSIGNED_FILE)
cd -

rm -f *.list
echo MEDIA:	$MEDIA_SERIAL
echo PLATFORM:	$PLATFORM_SERIAL
echo SHARED:	$SHARED_SERIAL
echo TESTKEY:	$TESTKEY_SERIAL
echo GOOGLE:	$GOOGLE_SERIAL
echo MIUI:	$MIUI_SERIAL
echo PATCHROM	$PATCHROM_SERIAL
echo UNSIGNED:	$UNSIGNED_SERIAL
# exit 0
for file in $(find "$FW"/ -iname "*.jar" -or -iname "*.apk"); do 
  determine_key $file
done
