ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

UNISTRING_CFBASE_VERSION := 1.2

libunistring_CFbase-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://mirrors.kernel.org/gnu/libunistring/libunistring-$(UNISTRING_CFBASE_VERSION).tar.gz{$(comma).sig})
	$(call PGP_VERIFY,libunistring-$(UNISTRING_CFBASE_VERSION).tar.gz)
	$(call EXTRACT_TAR,libunistring-$(UNISTRING_CFBASE_VERSION).tar.gz,libunistring-$(UNISTRING_CFBASE_VERSION),libunistring)
	sed -i.bk 's/-Wl,-framework -Wl,CoreServices//g' $(BUILD_WORK)/libunistring/configure

ifneq ($(wildcard $(BUILD_WORK)/libunistring/.build_complete),)
libunistring_CFbase:
	@echo "Using previously built libunistring."
else
libunistring_CFbase: libunistring_CFbase-setup
	cd $(BUILD_WORK)/libunistring && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libunistring
	+$(MAKE) -C $(BUILD_WORK)/libunistring install \
		DESTDIR=$(BUILD_STAGE)/libunistring
	$(call AFTER_BUILD,copy)
endif

libunistring_CFbase-package:: DEB_UNISTRING_V ?= $(UNISTRING_CFBASE_VERSION)
libunistring_CFbase-package: libunistring_CFbase-stage
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

.PHONY: libunistring_CFbase libunistring_CFbase-package
