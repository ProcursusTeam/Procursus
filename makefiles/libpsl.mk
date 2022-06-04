ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libpsl
LIBPSL_VERSION := 0.21.1
LIBPSL_API_V := 5
DEB_LIBPSL_V   ?= $(LIBPSL_VERSION)

libpsl-setup: setup
	$(call GITHUB_ARCHIVE,rockdaboot,libpsl,$(LIBPSL_VERSION),$(LIBPSL_VERSION))
	$(call GITHUB_ARCHIVE,publicsuffix,list,master,master,publicsuffix-list)
	$(call EXTRACT_TAR,libpsl-$(LIBPSL_VERSION).tar.gz,libpsl-$(LIBPSL_VERSION),libpsl)
	rm -rf $(BUILD_WORK)/libpsl/list
	$(call EXTRACT_TAR,publicsuffix-list-master.tar.gz,list-master,libpsl/list)

ifneq ($(wildcard $(BUILD_WORK)/libpsl/.build_complete),)
libpsl:
	@echo "Using previously built libpsl."
else
libpsl: libpsl-setup icu4c libidn2 libunistring
	cd $(BUILD_WORK)/libpsl && ./autogen.sh
	cd $(BUILD_WORK)/libpsl && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libpsl
	+$(MAKE) -C $(BUILD_WORK)/libpsl install \
		DESTDIR=$(BUILD_STAGE)/libpsl
	$(call AFTER_BUILD,copy)
endif

libpsl-package: libpsl-stage
	# libpsl.mk Package Structure
	rm -rf $(BUILD_DIST)/psl \
		$(BUILD_DIST)/libpsl{$(LIBPSL_API_V),-dev}
	mkdir -p $(BUILD_DIST)/psl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 \
		$(BUILD_DIST)/libpsl{$(LIBPSL_API_V),-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libpsl.mk Prep psl
	cp -a $(BUILD_STAGE)/libpsl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/psl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libpsl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/psl.1.zst $(BUILD_DIST)/psl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1

	# libpsl.mk Prep libpsl$(LIBPSL_API_V)
	cp -a $(BUILD_STAGE)/libpsl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpsl.$(LIBPSL_API_V).dylib $(BUILD_DIST)/libpsl$(LIBPSL_API_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libpsl.mk Prep libpsl-dev
	cp -a $(BUILD_STAGE)/libpsl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libpsl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libpsl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpsl.{dylib,a} $(BUILD_DIST)/libpsl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libpsl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig  $(BUILD_DIST)/libpsl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libpsl.mk Sign
	$(call SIGN,psl,general.xml)
	$(call SIGN,libpsl$(LIBPSL_API_V),general.xml)

	# libpsl.mk Make .debs
	$(call PACK,psl,DEB_LIBPSL_V)
	$(call PACK,libpsl$(LIBPSL_API_V),DEB_LIBPSL_V)
	$(call PACK,libpsl-dev,DEB_LIBPSL_V)

	# libpsl.mk Build cleanup
	rm -rf $(BUILD_DIST)/psl \
		$(BUILD_DIST)/libpsl{$(LIBPSL_API_V),-dev}

.PHONY: libpsl libpsl-package
