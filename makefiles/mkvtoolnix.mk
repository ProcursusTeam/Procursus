ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += mkvtoolnix
MKVTOOLNIX_VERSION := 56.1.0
DEB_MKVTOOLNIX_V   ?= $(MKVTOOLNIX_VERSION)

ifeq ($(shell [ "$(CFVER_WHOLE)" -lt 1600 ] && echo 1),1)
	$(error "MKVToolNix requires C++17 features only available on iOS13, MacOS Catalina and newer.")
endif

mkvtoolnix-setup: setup
ifneq ($(call HAS_COMMAND,rake),1)
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
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-debug \
		--with-boost="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		--with-docbook-xsl-root="$(DOCBOOK_XSL)" \
		--with-extra-includes="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include"\
		--with-extra-libs="$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib" \
		--disable-qt

	cd $(BUILD_WORK)/mkvtoolnix && rake -j$(shell $(GET_LOGICAL_CORES))
	cd $(BUILD_WORK)/mkvtoolnix && rake install \
		DESTDIR="$(BUILD_STAGE)/mkvtoolnix"

	touch $(BUILD_WORK)/mkvtoolnix/.build_complete
endif

mkvtoolnix-package: mkvtoolnix-stage
	# mkvtoolnix.mk Package Structure
	rm -rf $(BUILD_DIST)/mkvtoolnix
	mkdir -p $(BUILD_DIST)/mkvtoolnix$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# mkvtoolnix.mk Prep mkvtoolnix
	cp -a $(BUILD_STAGE)/mkvtoolnix$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/mkvtoolnix$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/mkvtoolnix$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 $(BUILD_DIST)/mkvtoolnix$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# mkvtoolnix.mk Sign
	$(call SIGN,mkvtoolnix,general.xml)

	# mkvtoolnix.mk Make .debs
	$(call PACK,mkvtoolnix,DEB_MKVTOOLNIX_V)

	# mkvtoolnix.mk Build cleanup
	rm -rf $(BUILD_DIST)/mkvtoolnix

.PHONY: mkvtoolnix mkvtoolnix-package
