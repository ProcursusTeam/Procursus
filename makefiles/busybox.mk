ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += busybox
BUSYBOX_VERSION := 1.35.0
DEB_BUSYBOX_V   ?= $(BUSYBOX_VERSION)

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
BUSYBOX_EXTRA_LDFLAGS := -lcrypt
endif

busybox-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://busybox.net/downloads/busybox-$(BUSYBOX_VERSION).tar.bz2{,.sig}
	$(call PGP_VERIFY,busybox-1.35.0.tar.bz2)
	$(call EXTRACT_TAR,busybox-$(BUSYBOX_VERSION).tar.bz2,busybox-$(BUSYBOX_VERSION),busybox)
	$(call DO_PATCH,busybox,busybox,-p1)
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	sed -i '/include <crypt.h>/d' $(BUILD_WORK)/busybox/libbb/pw_encrypt.c
endif
	cp -a $(BUILD_MISC)/busybox/.config $(BUILD_WORK)/busybox
	mkdir -p $(BUILD_WORK)/busybox/include/sys
	cp -a $(BUILD_MISC)/busybox/stat.h $(BUILD_WORK)/busybox/include/sys
	sed -i -e 's|/usr|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' -e 's|/etc|$(MEMO_PREFIX)/etc|g' -e 's|/var|$(MEMO_PREFIX)/var|g' \
		$$(find $(BUILD_WORK)/busybox -name '*.c') $$(find $(BUILD_WORK)/busybox -name '*.h')
	mkdir -p $(BUILD_STAGE)/busybox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/busybox/.build_complete),)
busybox:
	@echo "Using previously built busybox."
else
ifneq (,$(findstring darwin,$(MEMO_TARGET)))
busybox: busybox-setup
else
busybox: busybox-setup libxcrypt
endif
	$(CC) $(CFLAGS) -fembed-bitcode=off -c $(BUILD_MISC)/busybox/shims.c -o $(BUILD_WORK)/busybox/shims.o
	+cd $(BUILD_WORK)/busybox && $(MAKE) -C $(BUILD_WORK)/busybox \
		EXTRA_CFLAGS="$(CFLAGS) -std=gnu11 -fcommon -fembed-bitcode=off -D_BSD_SOURCE" \
		EXTRA_LDFLAGS="$(LDFLAGS) $(BUSYBOX_EXTRA_LDFLAGS) -fcommon" \
		EXTRA_ARFLAGS="$(BUILD_WORK)/busybox/shims.o" \
		LD="$(CC)" \
		CC="$(CC)" \
		AR="$(AR)" \
		SKIP_STRIP=y;
	$(INSTALL) -m4755 $(BUILD_WORK)/busybox/busybox $(BUILD_STAGE)/busybox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(call AFTER_BUILD)
endif

busybox-package: busybox-stage
	# busybox.mk Package Structure
	rm -rf $(BUILD_DIST)/busybox

	# busybox.mk Prep busybox
	cp -a $(BUILD_STAGE)/busybox $(BUILD_DIST)

	# busybox.mk Sign
	$(call SIGN,busybox,dd.xml)

	# busybox.mk Permissions
	$(FAKEROOT) chown 0:0 -R $(BUILD_STAGE)/busybox
	$(FAKEROOT) chmod u+s $(BUILD_STAGE)/busybox/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/busybox

	# busybox.mk Make .debs
	$(call PACK,busybox,DEB_BUSYBOX_V,2)

	# busybox.mk Build cleanup
	rm -rf $(BUILD_DIST)/busybox

.PHONY: busybox busybox-package
