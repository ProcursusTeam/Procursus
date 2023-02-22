ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += nghttp3
NGHTTP3_VERSION := 0.8.0
DEB_NGHTTP3_V   ?= $(NGHTTP3_VERSION)

nghttp3-setup: setup
	$(call GITHUB_ARCHIVE,ngtcp2,nghttp3,$(NGHTTP3_VERSION),v$(NGHTTP3_VERSION))
	$(call EXTRACT_TAR,nghttp3-$(NGHTTP3_VERSION).tar.gz,nghttp3-$(NGHTTP3_VERSION),nghttp3)

ifneq ($(wildcard $(BUILD_WORK)/nghttp3/.build_complete),)
nghttp3:
	@echo "Using previously built nghttp3."
else
nghttp3: nghttp3-setup
	cd $(BUILD_WORK)/nghttp3 && autoreconf -fi
	cd $(BUILD_WORK)/nghttp3 && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/nghttp3
	+$(MAKE) -C $(BUILD_WORK)/nghttp3 install \
		DESTDIR="$(BUILD_STAGE)/nghttp3"
	$(call AFTER_BUILD,copy)
endif

nghttp3-package: nghttp3-stage
	# nghttp3.mk Package Structure
	rm -rf $(BUILD_DIST)/libnghttp3-{3,dev}
	mkdir -p $(BUILD_DIST)/libnghttp3-{3,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# nghttp3.mk Prep libnghttp3-3
	cp -a $(BUILD_STAGE)/nghttp3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libnghttp3.3.dylib $(BUILD_DIST)/libnghttp3-3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# nghttp3.mk Prep libnghttp3-dev
	cp -a $(BUILD_STAGE)/nghttp3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libnghttp3.3.dylib) $(BUILD_DIST)/libnghttp3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/nghttp3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libnghttp3-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# nghttp3.mk Sign
	$(call SIGN,libnghttp3-3,general.xml)

	# nghttp3.mk Make .debs
	$(call PACK,libnghttp3-3,DEB_NGHTTP3_V)
	$(call PACK,libnghttp3-dev,DEB_NGHTTP3_V)

	# nghttp3.mk Build cleanup
	rm -rf $(BUILD_DIST)/libnghttp3-{3,dev}

.PHONY: nghttp3 nghttp3-package
