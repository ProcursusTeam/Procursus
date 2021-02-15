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
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
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
		$(BUILD_DIST)/gdbmtool
	mkdir -p \
		$(BUILD_DIST)/gdbm-l10n/usr/share \
		$(BUILD_DIST)/libgdbm-dev/usr/lib \
		$(BUILD_DIST)/libgdbm6/usr/{lib,share} \
		$(BUILD_DIST)/{libgdbm-dev,gdbmtool}/usr/share/man

	# libgdbm.mk Prep gdbmtool
	cp -a $(BUILD_STAGE)/libgdbm/usr/bin $(BUILD_DIST)/gdbmtool/usr
	cp -a $(BUILD_STAGE)/libgdbm/usr/share/man/man1 $(BUILD_DIST)/gdbmtool/usr/share/man

	# libgdbm.mk Prep libgdbm-dev
	cp -a $(BUILD_STAGE)/libgdbm/usr/include $(BUILD_DIST)/libgdbm-dev/usr
	cp -a $(BUILD_STAGE)/libgdbm/usr/share/man/man3 $(BUILD_DIST)/libgdbm-dev/usr/share/man
	cp -a $(BUILD_STAGE)/libgdbm/usr/share/info $(BUILD_DIST)/libgdbm-dev/usr/share
	cp -a $(BUILD_STAGE)/libgdbm/usr/lib/libgdbm.{a,dylib} $(BUILD_DIST)/libgdbm-dev/usr/lib

	# libgdbm.mk Prep libgdbm6
	cp -a $(BUILD_STAGE)/libgdbm/usr/lib/libgdbm.6.dylib $(BUILD_DIST)/libgdbm6/usr/lib
	cp -a $(BUILD_STAGE)/libgdbm/usr/share/locale $(BUILD_DIST)/libgdbm6/usr/share

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
		$(BUILD_DIST)/gdbmtool

.PHONY: libgdbm libgdbm-package
