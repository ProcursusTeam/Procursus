ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += icu4c
ICU_VERSION := 69.1
ICU_API_V   := $(shell echo $(ICU_VERSION) | cut -f1 -d.)
DEB_ICU_V   ?= $(ICU_VERSION)

icu4c-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) \
		https://github.com/unicode-org/icu/releases/download/release-$(shell echo $(ICU_VERSION) | $(SED) 's/\./-/')/icu4c-$(shell echo $(ICU_VERSION) | $(SED) 's/\./_/g')-src.tgz
	$(call EXTRACT_TAR,icu4c-$(shell echo $(ICU_VERSION) | $(SED) 's/\./_/g')-src.tgz,icu,icu4c)
	mkdir -p $(BUILD_WORK)/icu4c/host

ifneq ($(wildcard $(BUILD_WORK)/icu4c/.build_complete),)
icu4c:
	@echo "Using previously built icu4c."
else
icu4c: .SHELLFLAGS=-O extglob -c
icu4c: icu4c-setup
	cd $(BUILD_WORK)/icu4c/host && ../source/configure \
			$(BUILD_CONFIGURE_FLAGS); \
		$(MAKE) -C $(BUILD_WORK)/icu4c/host
	cd $(BUILD_WORK)/icu4c/source && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-cross-build=$(BUILD_WORK)/icu4c/host \
		--disable-samples \
		--disable-tests \
		LDFLAGS="$(LDFLAGS) -headerpad_max_install_names"
	+$(MAKE) -C $(BUILD_WORK)/icu4c/source
	+$(MAKE) -C $(BUILD_WORK)/icu4c/source install \
		DESTDIR=$(BUILD_STAGE)/icu4c
	+$(MAKE) -C $(BUILD_WORK)/icu4c/source install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/icu4c/.build_complete

	for lib in $(BUILD_STAGE)/icu4c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicu*.$(ICU_VERSION).dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicu*.$(ICU_VERSION).dylib; do \
		$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/$${basename $${lib} .$(ICU_VERSION).dylib}.$(ICU_API_V).dylib $$lib; \
		ln -sf $${basename $${lib} .$(ICU_VERSION).dylib}.$(ICU_VERSION).dylib $${echo $$lib | cut -d. -f-1}.$(ICU_API_V).dylib; \
		ln -sf $${basename $${lib} .$(ICU_VERSION).dylib}.$(ICU_API_V).dylib $${echo $$lib | cut -d. -f-1}.dylib; \
	done

	for stuff in $(BUILD_STAGE)/icu4c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicu*.$(ICU_VERSION).dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicu*.$(ICU_VERSION).dylib $(BUILD_STAGE)/icu4c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/!(icu-config); do \
		$(I_N_T) -change libicudata.$(ICU_API_V).dylib $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicudata.$(ICU_API_V).dylib $$stuff; \
		$(I_N_T) -change libicui18n.$(ICU_API_V).dylib $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicui18n.$(ICU_API_V).dylib $$stuff; \
		$(I_N_T) -change libicuio.$(ICU_API_V).dylib $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicuio.$(ICU_API_V).dylib $$stuff; \
		$(I_N_T) -change libicutest.$(ICU_API_V).dylib $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicutest.$(ICU_API_V).dylib $$stuff; \
		$(I_N_T) -change libicutu.$(ICU_API_V).dylib $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicutu.$(ICU_API_V).dylib $$stuff; \
		$(I_N_T) -change libicuuc.$(ICU_API_V).dylib $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicuuc.$(ICU_API_V).dylib $$stuff; \
	done
endif

icu4c-package: icu4c-stage
	# icu4c.mk Package Structure
	rm -rf $(BUILD_DIST)/libicu{$(ICU_API_V),-dev} \
		$(BUILD_DIST)/icu-devtools
	mkdir -p $(BUILD_DIST)/libicu{$(ICU_API_V),-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libicu-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share \
		$(BUILD_DIST)/icu-devtools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# icu4c.mk Prep libicu$(ICU_API_V)
	cp -a $(BUILD_STAGE)/icu4c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicu*.$(ICU_API_V)*.dylib $(BUILD_DIST)/libicu$(ICU_API_V)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# icu4c.mk Prep libicu-dev
	cp -a $(BUILD_STAGE)/icu4c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicu{data,i18n,io,test,tu,uc}.dylib $(BUILD_DIST)/libicu-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/icu4c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,icu} $(BUILD_DIST)/libicu-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/icu4c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/icu $(BUILD_DIST)/libicu-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# icu4c.mk Prep icu-devtools
	cp -a $(BUILD_STAGE)/icu4c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{sbin,bin,share} $(BUILD_DIST)/icu-devtools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	rm -f $(BUILD_DIST)/icu-devtools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/icu-config
	rm -f $(BUILD_DIST)/icu-devtools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/icu-config.1
	rm -rf $(BUILD_DIST)/icu-devtools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/icu

	# icu4c.mk Sign
	$(call SIGN,libicu$(ICU_API_V),general.xml)
	$(call SIGN,icu-devtools,general.xml)

	# icu4c.mk Make .debs
	$(call PACK,libicu$(ICU_API_V),DEB_ICU_V)
	$(call PACK,libicu-dev,DEB_ICU_V)
	$(call PACK,icu-devtools,DEB_ICU_V)

	# icu4c.mk Build cleanup
	rm -rf $(BUILD_DIST)/libicu{$(ICU_API_V),-dev} \
		$(BUILD_DIST)/icu-devtools

.PHONY: icu4c icu4c-package
