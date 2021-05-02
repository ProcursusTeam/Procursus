ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libgdbm
LIBGDBM_VERSION := 1.19
DEB_LIBGDBM_V   ?= $(LIBGDBM_VERSION)

libgdbm-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/gdbm/gdbm-$(LIBGDBM_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,gdbm-$(LIBGDBM_VERSION).tar.gz)
	$(call EXTRACT_TAR,gdbm-$(LIBGDBM_VERSION).tar.gz,gdbm-$(LIBGDBM_VERSION),libgdbm)

ifneq ($(wildcard $(BUILD_WORK)/libgdbm/.build_complete),)
libgdbm:
	@echo "Using previously built libgdbm."
else
libgdbm: libgdbm-setup readline gettext
	cd $(BUILD_WORK)/libgdbm && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libgdbm
	+$(MAKE) -C $(BUILD_WORK)/libgdbm install \
		DESTDIR=$(BUILD_STAGE)/libgdbm
	+$(MAKE) -C $(BUILD_WORK)/libgdbm install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libgdbm/.build_complete
endif

libgdbm-package: libgdbm-stage
	# libgdbm.mk Package Structure
	rm -rf \
		$(BUILD_DIST)/libgdbm{-dev,6} \
		$(BUILD_DIST)/gdbmtool \
		$(BUILD_DIST)/gdbm-l10n
	mkdir -p \
		$(BUILD_DIST)/gdbm-l10n/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share \
		$(BUILD_DIST)/libgdbm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libgdbm6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,share} \
		$(BUILD_DIST)/{libgdbm-dev,gdbmtool}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# libgdbm.mk Prep gdbmtool
	cp -a $(BUILD_STAGE)/libgdbm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/gdbmtool/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libgdbm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 $(BUILD_DIST)/gdbmtool/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# libgdbm.mk Prep libgdbm-dev
	cp -a $(BUILD_STAGE)/libgdbm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libgdbm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libgdbm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 $(BUILD_DIST)/libgdbm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man
	cp -a $(BUILD_STAGE)/libgdbm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/info $(BUILD_DIST)/libgdbm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	cp -a $(BUILD_STAGE)/libgdbm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgdbm.{a,dylib} $(BUILD_DIST)/libgdbm-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libgdbm.mk Prep libgdbm6
	cp -a $(BUILD_STAGE)/libgdbm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgdbm.6.dylib $(BUILD_DIST)/libgdbm6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libgdbm/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/locale $(BUILD_DIST)/libgdbm6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# libgdbm.mk Sign
	$(call SIGN,gdbmtool,general.xml)
	$(call SIGN,libgdbm6,general.xml)

	# libgdbm.mk Make .debs
	$(call PACK,gdbmtool,DEB_LIBGDBM_V)
	$(call PACK,libgdbm-dev,DEB_LIBGDBM_V)
	$(call PACK,libgdbm6,DEB_LIBGDBM_V)

	# libgdbm.mk Build cleanup
	rm -rf \
		$(BUILD_DIST)/libgdbm{-dev,6} \
		$(BUILD_DIST)/gdbmtool \
		$(BUILD_DIST)/gdbm-l10n

.PHONY: libgdbm libgdbm-package
