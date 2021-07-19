ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += mandoc
MANDOC_VERSION := 1.14.5
DEB_MANDOC_V   ?= $(MANDOC_VERSION)

mandoc-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://mandoc.bsd.lv/snapshots/mandoc-$(MANDOC_VERSION).tar.gz
	$(call EXTRACT_TAR,mandoc-$(MANDOC_VERSION).tar.gz,mandoc-$(MANDOC_VERSION),mandoc)
	$(call DO_PATCH,mandoc,mandoc,-p1)
	$(SED) -i -e 's|@CC@|$(CC)|' \
		-e 's|@CFLAGS@|$(CFLAGS)|' \
		-e 's|@CPPFLAGS@|$(CPPFLAGS)|' \
		-e 's|@LDFLAGS@|$(LDFLAGS)|' \
		-e 's|@MEMO_PREFIX@|$(MEMO_PREFIX)|g' \
		-e 's|@MEMO_SUB_PREFIX@|$(MEMO_SUB_PREFIX)|g' \
		$(BUILD_WORK)/mandoc/configure.local
	$(SED) -i '/int dummy;/d' \
		$(BUILD_WORK)/mandoc/compat_*.c
	$(SED) -i 's|ar rs|$(AR) rs|' \
		$(BUILD_WORK)/mandoc/Makefile

ifneq ($(wildcard $(BUILD_WORK)/mandoc/.build_complete),)
mandoc:
	@echo "Using previously built mandoc."
else
mandoc: mandoc-setup
	cd $(BUILD_WORK)/mandoc && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/mandoc \
		LDADD="-lz"
	+$(MAKE) -C $(BUILD_WORK)/mandoc install \
		DESTDIR=$(BUILD_STAGE)/mandoc
	touch $(BUILD_WORK)/mandoc/.build_complete
endif

mandoc-package: mandoc-stage
	# mandoc.mk Package Structure
	rm -rf $(BUILD_DIST)/mandoc
	
	# mandoc.mk Prep mandoc
	cp -a $(BUILD_STAGE)/mandoc $(BUILD_DIST)/mandoc
	
	# mandoc.mk Sign
	$(call SIGN,mandoc,general.xml)
	
	# mandoc.mk Make .debs
	$(call PACK,mandoc,DEB_MANDOC_V)
	
	# mandoc.mk Build cleanup
	rm -rf $(BUILD_DIST)/mandoc

.PHONY: mandoc mandoc-package
