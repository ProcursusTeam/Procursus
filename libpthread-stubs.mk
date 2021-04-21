ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS              += libpthread-stubs
LIBPTHREAD-STUBS_VERSION := 0.4
DEB_LIBPTHREAD-STUBS_V   ?= $(LIBPTHREAD-STUBS_VERSION)

libpthread-stubs-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://xorg.freedesktop.org/archive/individual/xcb/libpthread-stubs-$(LIBPTHREAD-STUBS_VERSION).tar.gz
	$(call EXTRACT_TAR,libpthread-stubs-$(LIBPTHREAD-STUBS_VERSION).tar.gz,libpthread-stubs-$(LIBPTHREAD-STUBS_VERSION),libpthread-stubs)

ifneq ($(wildcard $(BUILD_WORK)/libpthread-stubs/.build_complete),)
libpthread-stubs:
	@echo "Using previously built libpthread-stubs."
else
libpthread-stubs: libpthread-stubs-setup
	cd $(BUILD_WORK)/libpthread-stubs && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libpthread-stubs
	+$(MAKE) -C $(BUILD_WORK)/libpthread-stubs install \
		DESTDIR=$(BUILD_STAGE)/libpthread-stubs
	+$(MAKE) -C $(BUILD_WORK)/libpthread-stubs install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libpthread-stubs/.build_complete
endif

libpthread-stubs-package: libpthread-stubs-stage
	# libpthread-stubs.mk Package Structure
	rm -rf $(BUILD_DIST)/libpthread-stubs0-dev
	mkdir -p $(BUILD_DIST)/libpthread-stubs0-dev

	# libpthread-stubs.mk Prep libpthread-stubs0-dev
	cp -a $(BUILD_STAGE)/libpthread-stubs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) $(BUILD_DIST)/libpthread-stubs0-dev

	# libpthread-stubs.mk Make .debs
	$(call PACK,libpthread-stubs0-dev,DEB_LIBPTHREAD-STUBS_V)

	# libpthread-stubs.mk Build cleanup
	rm -rf $(BUILD_DIST)/libpthread-stubs0-dev

.PHONY: libpthread-stubs libpthread-stubs-package