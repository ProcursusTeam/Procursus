ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += lcms2
LCMS2_VERSION := 2.12
DEB_LCMS2_V   ?= $(LCMS2_VERSION)

lcms2-setup: setup
	wget -q -nc -L -P $(BUILD_SOURCE) \
		https://downloads.sourceforge.net/lcms/lcms2-$(LCMS2_VERSION).tar.gz
	$(call EXTRACT_TAR,lcms2-$(LCMS2_VERSION).tar.gz,lcms2-$(LCMS2_VERSION),lcms2)

ifneq ($(wildcard $(BUILD_WORK)/lcms2/.build_complete),)
lcms2:
	@echo "Using previously built lcms2."
else
lcms2: lcms2-setup libjpeg-turbo libtiff
	cd $(BUILD_WORK)/lcms2 && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/lcms2
	+$(MAKE) -C $(BUILD_WORK)/lcms2 install \
		DESTDIR="$(BUILD_STAGE)/lcms2"
	+$(MAKE) -C $(BUILD_WORK)/lcms2 install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/lcms2/.build_complete
endif

lcms2-package: lcms2-stage
	# lcms2.mk Package Structure
	rm -rf $(BUILD_DIST)/liblcms2-{2,dev,utils}
	mkdir -p \
		$(BUILD_DIST)/liblcms2-{2,dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/liblcms2-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# lcms2.mk Prep liblcms2-dev
	cp -a $(BUILD_STAGE)/lcms2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/liblcms2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/lcms2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(liblcms2.2.dylib) $(BUILD_DIST)/liblcms2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# lcms2.mk Prep liblcms2-utils
	cp -a $(BUILD_STAGE)/lcms2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/liblcms2-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/lcms2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 $(BUILD_DIST)/liblcms2-utils/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# lcms2.mk Prep liblcms2-2
	cp -a $(BUILD_STAGE)/lcms2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/liblcms2.2.dylib $(BUILD_DIST)/liblcms2-2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# lcms2.mk Sign
	$(call SIGN,liblcms2-2,general.xml)
	$(call SIGN,liblcms2-utils,general.xml)

	# lcms2.mk Make .debs
	$(call PACK,liblcms2-dev,DEB_LCMS2_V)
	$(call PACK,liblcms2-utils,DEB_LCMS2_V)
	$(call PACK,liblcms2-2,DEB_LCMS2_V)

	# lcms2.mk Build cleanup
	rm -rf $(BUILD_DIST)/liblcms2-{2,dev,utils}

.PHONY: lcms2 lcms2-package
