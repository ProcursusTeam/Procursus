ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += dmg2img
DMG2IMG_VERSION := 1.6.7
DEB_DMG2IMG_V   ?= $(DMG2IMG_VERSION)

dmg2img-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://deb.debian.org/debian/pool/main/d/dmg2img/dmg2img_$(DMG2IMG_VERSION).orig.tar.gz
	$(call EXTRACT_TAR,dmg2img_$(DMG2IMG_VERSION).orig.tar.gz,dmg2img-$(DMG2IMG_VERSION),dmg2img)
	$(call DO_PATCH,dmg2img,dmg2img,-p1)

ifneq ($(wildcard $(BUILD_WORK)/dmg2img/.build_complete),)
dmg2img:
	@echo "Using previously built dmg2img."
else
dmg2img: dmg2img-setup openssl
	+$(MAKE) -C $(BUILD_WORK)/dmg2img \
		CC="$(CC) $(LDFLAGS)" \
		CFLAGS="$(CFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/dmg2img install \
		DESTDIR="$(BUILD_STAGE)/dmg2img"
	$(INSTALL) -Dm644 $(BUILD_WORK)/dmg2img/vfdecrypt.1 $(BUILD_STAGE)/dmg2img/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/vfdecrypt.1
	$(INSTALL) -Dm644 $(BUILD_INFO)/dmg2img.1 $(BUILD_STAGE)/dmg2img/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/dmg2img.1
	touch $(BUILD_WORK)/dmg2img/.build_complete
endif

dmg2img-package: dmg2img-stage
	# dmg2img.mk Package Structure
	rm -rf $(BUILD_DIST)/dmg2img

	# dmg2img.mk Prep dmg2img
	cp -a $(BUILD_STAGE)/dmg2img $(BUILD_DIST)

	# dmg2img.mk Sign
	$(call SIGN,dmg2img,general.xml)

	# dmg2img.mk Make .debs
	$(call PACK,dmg2img,DEB_DMG2IMG_V)

	# dmg2img.mk Build cleanup
	rm -rf $(BUILD_DIST)/dmg2img

.PHONY: dmg2img dmg2img-package
