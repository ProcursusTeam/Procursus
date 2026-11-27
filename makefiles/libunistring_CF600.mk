ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

UNISTRING_CF600_VERSION := 1.2

libunistring_CF600-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://mirrors.kernel.org/gnu/libunistring/libunistring-$(UNISTRING_CF600_VERSION).tar.gz{$(comma).sig})
	$(call PGP_VERIFY,libunistring-$(UNISTRING_CF600_VERSION).tar.gz)
	$(call EXTRACT_TAR,libunistring-$(UNISTRING_CF600_VERSION).tar.gz,libunistring-$(UNISTRING_CF600_VERSION),libunistring)

ifneq ($(wildcard $(BUILD_WORK)/libunistring/.build_complete),)
libunistring_CF600:
	@echo "Using previously built libunistring."
else
libunistring_CF600: libunistring_CF600-setup
	cd $(BUILD_WORK)/libunistring && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libunistring
	+$(MAKE) -C $(BUILD_WORK)/libunistring install \
		DESTDIR=$(BUILD_STAGE)/libunistring
	$(call AFTER_BUILD,copy)
endif

libunistring_CF600-package:: DEB_UNISTRING_V ?= $(UNISTRING_CF600_VERSION)
libunistring_CF600-package: libunistring_CF600-stage
	# libunistring.mk Package Structure
	rm -rf $(BUILD_DIST)/libunistring{5,-dev}
	mkdir -p $(BUILD_DIST)/libunistring{5,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libunistring.mk Prep libunistring5
	cp -a $(BUILD_STAGE)/libunistring/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libunistring.5.dylib $(BUILD_DIST)/libunistring5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libunistring.mk Prep libunistring-dev
	cp -a $(BUILD_STAGE)/libunistring/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libunistring.{dylib,a} $(BUILD_DIST)/libunistring-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libunistring/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libunistring-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libunistring.mk Sign
	$(call SIGN,libunistring5,general.xml)

	# libunistring.mk Make .debs
	$(call PACK,libunistring5,DEB_UNISTRING_V)
	$(call PACK,libunistring-dev,DEB_UNISTRING_V)

	# libunistring.mk Build cleanup
	rm -rf $(BUILD_DIST)/libunistring{5,-dev}

.PHONY: libunistring_CF600 libunistring_CF600-package
