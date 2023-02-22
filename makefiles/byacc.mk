ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += byacc
BYACC_VERSION := 20220114
DEB_BYACC_V   ?= $(BYACC_VERSION)

byacc-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://invisible-mirror.net/archives/byacc/byacc-$(BYACC_VERSION).tgz{$(comma).asc})
	$(call PGP_VERIFY,byacc-$(BYACC_VERSION).tgz,asc)
	$(call EXTRACT_TAR,byacc-$(BYACC_VERSION).tgz,byacc-$(BYACC_VERSION),byacc)
	mkdir -p $(BUILD_WORK)/byacc/byacc{,2}-build

ifneq ($(wildcard $(BUILD_WORK)/byacc/.build_complete),)
byacc:
	@echo "Using previously built byacc."
else
byacc: byacc-setup
	cd $(BUILD_WORK)/byacc/byacc-build && ../configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--program-transform-name='s,^yacc,byacc,'
	+$(MAKE) -C $(BUILD_WORK)/byacc/byacc-build
	+$(MAKE) -C $(BUILD_WORK)/byacc/byacc-build install \
		DESTDIR=$(BUILD_STAGE)/byacc/byacc
	sed -i '/- an LALR/s,^..N,byacc,' \
		$(BUILD_STAGE)/byacc/byacc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/byacc.1
	cd $(BUILD_WORK)/byacc/byacc2-build && ../configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--enable-btyacc \
		--with-max-table-size=123456 \
		--program-transform-name='s,^yacc,byacc2,'
	+$(MAKE) -C $(BUILD_WORK)/byacc/byacc2-build
	+$(MAKE) -C $(BUILD_WORK)/byacc/byacc2-build install \
		DESTDIR=$(BUILD_STAGE)/byacc/byacc2
	sed -i '/- an LALR/s,^..N,byacc2,' \
		$(BUILD_STAGE)/byacc/byacc2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/byacc2.1
	$(call AFTER_BUILD,,byacc/byacc)
	$(call AFTER_BUILD,,byacc/byacc2)
endif

byacc-package: byacc-stage
	# byacc.mk Package Structure
	rm -rf $(BUILD_DIST)/byacc{,2}

	# byacc.mk Prep byacc
	cp -a $(BUILD_STAGE)/byacc/byacc $(BUILD_DIST)/byacc
	cp -a $(BUILD_STAGE)/byacc/byacc2 $(BUILD_DIST)/byacc2

	# byacc.mk Sign
	$(call SIGN,byacc,general.xml)
	$(call SIGN,byacc2,general.xml)

	# byacc.mk Make .debs
	$(call PACK,byacc,DEB_BYACC_V)
	$(call PACK,byacc2,DEB_BYACC_V)

	# byacc.mk Build cleanup
	rm -rf $(BUILD_DIST)/byacc{,2}

.PHONY: byacc byacc-package
