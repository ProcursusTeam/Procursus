ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += usbfluxd
USBFLUXD_COMMIT  := 0723a9a89a188de0949a6c80177705309ebb21f5
USBFLUXD_VERSION := 1.2.0+git20210920.$(shell echo $(USBFLUXD_COMMIT) | cut -c -7)
DEB_USBFLUXD_V   ?= $(USBFLUXD_VERSION)

usbfluxd-setup: setup
	$(call GITHUB_ARCHIVE,corellium,usbfluxd,$(USBFLUXD_VERSION),$(USBFLUXD_COMMIT))
	$(call EXTRACT_TAR,usbfluxd-$(USBFLUXD_VERSION).tar.gz,usbfluxd-$(USBFLUXD_COMMIT),usbfluxd)

ifneq ($(wildcard $(BUILD_WORK)/usbfluxd/.build_complete),)
usbfluxd:
	@echo "Using previously built usbfluxd."
else
usbfluxd: usbfluxd-setup libplist
	cd $(BUILD_WORK)/usbfluxd && ./autogen.sh \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-static-libplist="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libplist-2.0.a" \
		ac_cv_func_malloc_0_nonnull=yes \
		ac_cv_func_realloc_0_nonnull=yes
	+$(MAKE) -C $(BUILD_WORK)/usbfluxd \
		libplist_LIBS="-lplist-2.0"
	+$(MAKE) -C $(BUILD_WORK)/usbfluxd install \
		DESTDIR="$(BUILD_STAGE)/usbfluxd"
	mkdir -p $(BUILD_STAGE)/usbfluxd/$(MEMO_PREFIX)/Library/LaunchDaemons
	sed -e "s|@MEMO_PREFIX@|$(MEMO_PREFIX)|g" -e "s|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g" < $(BUILD_INFO)/com.corellium.usbfluxd.plist > $(BUILD_STAGE)/usbfluxd/$(MEMO_PREFIX)/Library/LaunchDaemons/com.corellium.usbfluxd.plist
	$(call AFTER_BUILD)
endif

usbfluxd-package: usbfluxd-stage
	# usbfluxd.mk Package Structure
	rm -rf $(BUILD_DIST)/usbfluxd

	# usbfluxd.mk Prep usbfluxd
	cp -a $(BUILD_STAGE)/usbfluxd $(BUILD_DIST)

	# usbfluxd.mk Sign
	$(call SIGN,usbfluxd,general.xml)

	# usbfluxd.mk Make .debs
	$(call PACK,usbfluxd,DEB_USBFLUXD_V)

	# usbfluxd.mk Build cleanup
	rm -rf $(BUILD_DIST)/usbfluxd

.PHONY: usbfluxd usbfluxd-package
