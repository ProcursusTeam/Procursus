ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += mkvtoolnix
MKVTOOLNIX_VERSION := 53.0.0
DEB_MKVTOOLNIX_V   ?= $(MKVTOOLNIX_VERSION)

mkvtoolnix-setup: setup
ifeq (, $(shell which rake))
	$(error "No rake in PATH, please install ruby and rake, if you are on macOS you have broken something.")
endif

	wget -q -nc -P $(BUILD_SOURCE) https://mkvtoolnix.download/sources/mkvtoolnix-$(MKVTOOLNIX_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,mkvtoolnix-$(MKVTOOLNIX_VERSION).tar.xz)
	$(call EXTRACT_TAR,mkvtoolnix-$(MKVTOOLNIX_VERSION).tar.xz,mkvtoolnix-$(MKVTOOLNIX_VERSION),mkvtoolnix)

ifneq ($(wildcard $(BUILD_WORK)/mkvtoolnix/.build_complete),)
mkvtoolnix:
	@echo "Using previously built mkvtoolnix."
else

mkvtoolnix: mkvtoolnix-setup libboost flac libfmt gettext libebml file libmatroska libvorbis pcre2 libpugixml
	cd $(BUILD_WORK)/mkvtoolnix && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-debug \
		--with-boost="$(BUILD_BASE)/usr" \
		--with-docbook-xsl-root="$(DOCBOOK_XSL)" \
		--with-extra-includes="$(BUILD_BASE)/usr/include"\
		--with-extra-libs="$(BUILD_BASE)/usr/lib" \
		--disable-qt

	cd $(BUILD_WORK)/mkvtoolnix && rake -j$(shell $(GET_LOGICAL_CORES))
	cd $(BUILD_WORK)/mkvtoolnix && rake install \
		DESTDIR="$(BUILD_STAGE)/mkvtoolnix"

	touch $(BUILD_WORK)/mkvtoolnix/.build_complete
endif

mkvtoolnix-package: mkvtoolnix-stage
	# mkvtoolnix.mk Package Structure
	rm -rf $(BUILD_DIST)/mkvtoolnix
	mkdir -p $(BUILD_DIST)/mkvtoolnix/usr/share/man

	# mkvtoolnix.mk Prep mkvtoolnix7
	cp -a $(BUILD_STAGE)/mkvtoolnix/usr/bin $(BUILD_DIST)/mkvtoolnix/usr
	cp -a $(BUILD_STAGE)/mkvtoolnix/usr/share/man/man1 $(BUILD_DIST)/mkvtoolnix/usr/share/man

	# mkvtoolnix.mk Sign
	$(call SIGN,mkvtoolnix,general.xml)

	# mkvtoolnix.mk Make .debs
	$(call PACK,mkvtoolnix,DEB_MKVTOOLNIX_V)

	# mkvtoolnix.mk Build cleanup
	rm -rf $(BUILD_DIST)/mkvtoolnix

.PHONY: mkvtoolnix mkvtoolnix-package
