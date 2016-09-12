MIUI_VERSION = MIUI8K
CMDLINE = console=ttyHSL0,115200,n8 androidboot.hardware=qcom user_debug=23 msm_rtb.filter=0x3b7 ehci-hcd.park=3 androidboot.bootdevice=msm_sdcc.1
OTAVER := miui-$(shell date +%Y%m%d-%H%M)-d10f-$(MIUI_VERSION)
ZIP     = MIUI8_d10f_by_S-trace_latest.zip
NAME    = $(OTAVER).zip
ORIGIN  = $(shell ls xiaomi.eu_multi_HM1SWC_*_v8-4.4.zip|sort|tail -n1)
FW_DIR  = FW
.PHONY: all clean tools ramdisk boot.img zip sideload rboot fboot install otaver keys # This rules does not creating files
.SUFFIXES: # Disabling built-in Make rules

all:  install

clean:
	$(MAKE) -C tools/bootimg clean
	rm -rf miui-*.zip *.list $(FW_DIR) boot tmp

tools: tools/bootimg/mkbootimg tools/bootimg/unpackbootimg
tools/bootimg/mkbootimg:
	$(MAKE) -C tools/bootimg mkbootimg
tools/bootimg/unpackbootimg:
	$(MAKE) -C tools/bootimg unpackbootimg

keys: keys/$(MIUI_VERSION)
keys/$(MIUI_VERSION):
	mkdir -p keys/$(MIUI_VERSION)
	echo ""|./tools/make_key keys/$(MIUI_VERSION)/shared     "/CN=Shared key for $(MIUI_VERSION)/" ; true
	echo ""|./tools/make_key keys/$(MIUI_VERSION)/testkey    "/CN=Testkey for $(MIUI_VERSION)/" ; true
	echo ""|./tools/make_key keys/$(MIUI_VERSION)/media      "/CN=Media key for $(MIUI_VERSION)/" ; true
	echo ""|./tools/make_key keys/$(MIUI_VERSION)/platform   "/CN=Platform key for $(MIUI_VERSION)/" ; true

FW: tools/bootimg/unpackbootimg addons/*/$(FW_DIR)/* keys
	@echo "Unpacking origin $(ORIGIN)"
	@unzip $(ORIGIN) -d $(FW_DIR)/

	@echo "Cleaning up"
	@rm -rf $(FW_DIR)/*.mbn \
		$(FW_DIR)/*.bin \
		$(FW_DIR)/system/lib/modules/* \
		$(FW_DIR)/recovery \
		$(FW_DIR)/META-INF/CERT.* \
		$(FW_DIR)/META-INF/MANIFEST.* \
		$(FW_DIR)/META-INF/com/android/otacert

	@echo "Installing FW addons"
	@cp -r addons/*/$(FW_DIR)/* $(FW_DIR)/

	@echo "Applying FW patches"
	@for patch in `find addons/ -name *-FW-*.patch -type f|sort`; do echo "Applying $$patch"; patch -p1 < $$patch || exit 1; done
	@find -name *.orig -delete

	@echo "Determining signing keys"
	@./tools/determine_signing_keys.sh $(FW_DIR)

	@echo "Installing frameworks"
	@rm -rf tmp/
	@mkdir -p tmp
	@tools/apktool/apktool if FW/system/framework/framework-res.apk -t $(MIUI_VERSION) -p tmp/frameworks
	@tools/apktool/apktool if FW/system/app/miui.apk -t $(MIUI_VERSION) -p tmp/frameworks
	@tools/apktool/apktool if FW/system/framework/framework-ext-res.apk -t $(MIUI_VERSION) -p tmp/frameworks
	@tools/apktool/apktool if FW/system/app/miuisystem.apk -t $(MIUI_VERSION) -p tmp/frameworks

	@echo "Applying SMALI patches"
	@for patch in `find addons/ -name *-SMALI-*.patch -type f|sort --field-separator=/ --key=3`; do \
		file="`echo $$patch|cut -d '-' -f 3`"; \
		if ! echo $$file|fgrep -q .; then file="`echo $$patch|cut -d '-' -f 3-4`";fi ; \
		path="`find FW/ -name $$file`"; \
		echo "Applying $$patch to $$file ($$path)"; \
		cd tmp/; \
		../tools/apktool/apktool d -f -p frameworks -t $(MIUI_VERSION) "../$$path" -o "$$file"; \
		git init; \
		git add "$$file"; \
		git commit -m "Before patch $$patch"; \
		patch -p1 < ../$$patch || exit 1; \
		git add .; \
		git commit -m "After patch $$patch"; \
		extras_dir="../`dirname $$patch`/$$file"; \
		if [ -d "$$extras_dir" ]; then echo "Copying extras from $$extras_dir"; cp -rvf  $$extras_dir/* $$file/; else echo "Extras dir '$$extras_dir' not found"; fi; \
		find -name *.orig -delete; \
		echo origin md5sum: `md5sum "../$$path"`; \
		../tools/apktool/apktool b -p frameworks "$$file" -o "../$$path" || exit 1; \
		echo new md5sum: `md5sum "../$$path"`; \
		cd - ; \
	done

# 	@echo "Cleaning up"
# 	@rm -rf tmp/

	@echo "Resigning APKs"
	@for file in `find $(FW_DIR)/ -iname '*.apk'`; do ./tools/resign_apk.sh $$file `basename $$file|rev|cut -d . -f 2-|rev` $(MIUI_VERSION) || exit 1 ;done

	@echo "Updating build.prop data"
	@sed -i 's/armani/d10f/g' FW/system/build.prop
	@sed -i 's/xiaomi/jsr/g' FW/system/build.prop
	@sed -i 's/Xiaomi/JSR Tech/g' FW/system/build.prop
	@sed -i 's/release-keys/dev-keys/g' FW/system/build.prop
	@sed -i "s/ro.com.google.clientidbase.*//g" FW/system/build.prop
	@sed -i "s/ro.build.type=.*/ro.build.type=userdebug/g" FW/system/build.prop
	@sed -i "s/ro.build.type=.*/ro.build.type=userdebug/g" FW/system/build.prop
	@sed -i "s/ro.product.model=.*/ro.product.model=D10F/g" FW/system/build.prop
	@sed -i "s/d10f-user/d10f-userdebug/g" FW/system/build.prop
	@sed -i "s :user/ :userdebug/ g" FW/system/build.prop
	@sed -i "/ro.adb.secure=.*/d" FW/system/build.prop

ramdisk: boot/ramdisk.cpio.gz
boot/ramdisk.cpio.gz: $(shell find boot/ramdisk/ -type f|sed 's/ /\\ /g') Makefile # ramdisk depends on all files in boot/ subdir and Makefile
	@echo "Creating dirs"
	@mkdir -p boot/ramdisk/proc
	@mkdir -p boot/ramdisk/sys
	@mkdir -p boot/ramdisk/dev
	@mkdir -p boot/ramdisk/data
	@mkdir -p boot/ramdisk/system
	@mkdir -p boot/ramdisk/persist
	@echo "Fixing permissions"
	@chmod 750 boot/ramdisk/init*.rc
	@chmod 640 boot/ramdisk/ueventd*.rc boot/ramdisk/fstab.* boot/ramdisk/*.prop
	@echo "Packing ramdisk"
	@cd boot/ramdisk; find | cpio -o -H newc --owner root:root | gzip -9 > ../ramdisk.cpio.gz

boot: $(shell find addons/*/boot/ -type f) tools/bootimg/unpackbootimg
	@echo "Unpacking origin boot.img"
	@mkdir -p boot/ramdisk
	@unzip $(ORIGIN) boot.img -d boot/
	@cd boot/; ../tools/bootimg/unpackbootimg -i boot.img;
	@echo "Unpacking origin ramdisk"
	@cd boot/ramdisk; zcat ../boot.img-ramdisk.gz |cpio -i
	@echo "Cleaning up"
	@rm -rf boot/boot.img*
	@echo "Installing boot addons"
	@cp -r addons/*/boot/* boot/
	@echo "Applying boot patches"
	@for patch in `find addons/ -name *-BOOT-*.patch -type f|sort --field-separator=/ --key=3`; do \
	echo "Applying $$patch"; \
	cd boot/ ; \
	git init; \
	git add .; \
	git commit -m "Before patch $$patch"; \
	patch -p1 < ../$$patch || exit 1; \
	git add .; \
	git commit -m "After patch $$patch"; \
	cd - ; \
	done
	@find -name *.orig -delete


boot.img:
$(FW_DIR)/boot.img: boot boot/kernel.zImage boot/dt.img boot/ramdisk.cpio.gz tools/bootimg/mkbootimg Makefile # boot.img depends on zImage, dt, ramdisk, mkbootimg and Makefile
	@echo "Packing bootimg"
	@./tools/bootimg/mkbootimg \
	--kernel boot/kernel.zImage \
	--ramdisk boot/ramdisk.cpio.gz \
	--cmdline "androidboot.selinux=permissive $(CMDLINE)" \
	--base 00000000 \
	--pagesize 2048 \
	--dt boot/dt.img \
	--ramdisk_offset 01000000 \
	--second_offset 00f00000 \
	--tags_offset 00000100 \
	--output $(FW_DIR)/boot.img

zip: $(ZIP)
$(ZIP): $(shell find $(FW_DIR) -type f|sed 's/ /\\ /g') FW $(FW_DIR)/boot.img Makefile # FW zip depends on all files in $(FW_DIR)/ subdir, $(FW_DIR)/ itself, boot and Makefile
	@echo "Packing flashable ZIP"
	@rm -f "$(ZIP)"
	@cd $(FW_DIR)/; zip -r "../$(ZIP)-unsigned" *
	@echo "Signing flashable ZIP"
	@java -jar tools/signapk.jar -a 4 keys/$(MIUI_VERSION)/platform.x509.pem keys/$(MIUI_VERSION)/platform.pk8 "$(ZIP)-unsigned" "$(ZIP)"
	@rm "$(ZIP)-unsigned"
	@ln "$(ZIP)" "$(NAME)"
	@echo $(ZIP) \($(NAME)\) built

sideload: $(ZIP)
	adb sideload $(ZIP)

rboot: $(FW_DIR)/boot.img
	adb reboot bootloader || true # not fatal
	fastboot boot $(FW_DIR)/boot.img

fboot: $(FW_DIR)/boot.img
	adb reboot bootloader || true # not fatal
	fastboot flash boot $(FW_DIR)/boot.img
	fastboot boot $(FW_DIR)/boot.img

otaver:
	@sed -i "s/ro.ota.current_rom.*//g" FW/system/build.prop
	echo ro.ota.current_rom=$(OTAVER) >> $(FW_DIR)/system/build.prop

install: $(ZIP)
	adb push -p $(ZIP) /external_sd/
	adb shell "twrp install /external_sd/$(ZIP)"
