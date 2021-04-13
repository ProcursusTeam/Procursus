ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += liblqr
LIBLQR_VERSION := 0.4.2
DEB_LIBLQR_V   ?= $(LIBLQR_VERSION)

liblqr-setup: setup
	$(call GITHUB_ARCHIVE,carlobaldassi,liblqr,$(LIBLQR_VERSION),v$(LIBLQR_VERSION))
	$(call EXTRACT_TAR,liblqr-$(LIBLQR_VERSION).tar.gz,liblqr-$(LIBLQR_VERSION),liblqr)
	$(call DO_PATCH,liblqr,liblqr,-p1)

ifneq ($(wildcard $(BUILD_WORK)/liblqr/.build_complete),)
liblqr:
	@echo "Using previously built liblqr."
else
liblqr: liblqr-setup glib2.0 gettext
	cd $(BUILD_WORK)/liblqr && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-dependency-tracking \
		--enable-install-man \
		GLIB_CFLAGS="-I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/glib-2.0 -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/glib-2.0/include -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/glib-2.0/include"
	+$(MAKE) -C $(BUILD_WORK)/liblqr
	+$(MAKE) -C $(BUILD_WORK)/liblqr install \
		DESTDIR=$(BUILD_STAGE)/liblqr
	+$(MAKE) -C $(BUILD_WORK)/liblqr install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/liblqr/.build_complete
endif

liblqr-package: liblqr-stage
	# liblqr.mk Package Structure
	rm -rf $(BUILD_DIST)/liblqr-1-0{,-dev}
	mkdir -p $(BUILD_DIST)/liblqr-1-0{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# liblqr.mk Prep liblqr-1-0
	cp -a $(BUILD_STAGE)/liblqr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblqr-1.0.dylib $(BUILD_DIST)/liblqr-1-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# liblqr.mk Prep liblqr-1-0-dev
	cp -a $(BUILD_STAGE)/liblqr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{liblqr-1.dylib,pkgconfig} $(BUILD_DIST)/liblqr-1-0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/liblqr/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,share} $(BUILD_DIST)/liblqr-1-0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# liblqr.mk Sign
	$(call SIGN,liblqr-1-0,general.xml)

	# liblqr.mk Make .debs
	$(call PACK,liblqr-1-0,DEB_LIBLQR_V)
	$(call PACK,liblqr-1-0-dev,DEB_LIBLQR_V)

	# liblqr.mk Build cleanup
	rm -rf $(BUILD_DIST)/liblqr-1-0{,-dev}

.PHONY: liblqr liblqr-package
