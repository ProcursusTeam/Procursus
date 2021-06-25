ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libgeneral
LIBGENERAL_VERSION := 54
LIBGENERAL_COMMIT  := b04a27d0584c4c10c4b376325bb928c0ad12e285
DEB_LIBGENERAL_V   ?= $(LIBGENERAL_VERSION)-1

libgeneral-setup: setup
	$(call GITHUB_ARCHIVE,tihmstar,libgeneral,$(LIBGENERAL_VERSION),$(LIBGENERAL_VERSION))
	$(call EXTRACT_TAR,libgeneral-$(LIBGENERAL_VERSION).tar.gz,libgeneral-$(LIBGENERAL_VERSION),libgeneral)
	
	$(SED) -i 's/git rev\-list \-\-count HEAD/printf ${LIBGENERAL_VERSION}/g' $(BUILD_WORK)/libgeneral/configure.ac
	$(SED) -i 's/git rev\-parse HEAD/printf ${LIBGENERAL_COMMIT}/g' $(BUILD_WORK)/libgeneral/configure.ac

ifneq ($(wildcard $(BUILD_WORK)/libgeneral/.build_complete),)
libgeneral:
	@echo "Using previously built libgeneral."
else
libgeneral: libgeneral-setup
	cd $(BUILD_WORK)/libgeneral && ./autogen.sh \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libgeneral
	+$(MAKE) -C $(BUILD_WORK)/libgeneral install \
		DESTDIR="$(BUILD_STAGE)/libgeneral"
	+$(MAKE) -C $(BUILD_WORK)/libgeneral install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libgeneral/.build_complete
endif

libgeneral-package: libgeneral-stage
	# libgeneral.mk Package Structure
	rm -rf $(BUILD_DIST)/libgeneral{0,-dev}
	mkdir -p $(BUILD_DIST)/libgeneral{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libgeneral.mk Prep libgeneral0
	cp -a $(BUILD_STAGE)/libgeneral/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgeneral.0.dylib $(BUILD_DIST)/libgeneral0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libgeneral.mk Prep libgeneral-dev
	cp -a $(BUILD_STAGE)/libgeneral/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libgeneral.0.dylib) $(BUILD_DIST)/libgeneral-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libgeneral/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libgeneral-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libgeneral.mk Sign
	$(call SIGN,libgeneral0,general.xml)

	# libgeneral.mk Make .debs
	$(call PACK,libgeneral0,DEB_LIBGENERAL_V)
	$(call PACK,libgeneral-dev,DEB_LIBGENERAL_V)

	# libgeneral.mk Build cleanup
	rm -rf $(BUILD_DIST)/libgeneral{0,-dev}

.PHONY: libgeneral libgeneral-package
