ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += icu4c
ICU_VERSION  := 69.1
DEB_ICU_V    ?= $(ICU_VERSION)

icu4c-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/icu4c-$(ICU_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/icu4c-$(ICU_VERSION).tar.gz \
			https://github.com/unicode-org/icu/releases/download/release-$(shell echo $(ICU_VERSION) | $(SED) 's/\./-/')/icu4c-$(shell echo $(ICU_VERSION) | $(SED) 's/\./_/')-src.tgz
	$(call EXTRACT_TAR,icu4c-$(ICU_VERSION).tar.gz,icu,icu4c)
	mkdir -p $(BUILD_WORK)/icu4c/host

ifneq ($(wildcard $(BUILD_WORK)/icu4c/.build_complete),)
icu4c:
	@echo "Using previously built icu4c."
else
icu4c: icu4c-setup
	cd $(BUILD_WORK)/icu4c/host && unset CC CXX CPP CFLAGS CPPFLAGS CXXFLAGS LDFLAGS RANLIB AR; \
		../source/configure; \
		$(MAKE) -C $(BUILD_WORK)/icu4c/host
	cd $(BUILD_WORK)/icu4c/source && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-cross-build=$(BUILD_WORK)/icu4c/host \
		--disable-samples \
		--disable-tests
	+$(MAKE) -C $(BUILD_WORK)/icu4c/source
	+$(MAKE) -C $(BUILD_WORK)/icu4c/source install \
		DESTDIR=$(BUILD_STAGE)/icu4c
	+$(MAKE) -C $(BUILD_WORK)/icu4c/source install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/icu4c/.build_complete

	for lib in $(BUILD_STAGE)/icu4c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicu*.69.1.dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicu*.69.1.dylib; do \
		$(I_N_T) -id $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/$$(echo $$lib | rev | cut -d. -f4 | cut -d/ -f1 | rev).69.dylib $$lib; \
		ln -sf $$(echo $$lib | rev | cut -d. -f4 | cut -d/ -f1 | rev).69.1.dylib $$(echo $$lib | rev | cut -d. -f4 | rev).69.dylib; \
		ln -sf $$(echo $$lib | rev | cut -d. -f4 | cut -d/ -f1 | rev).69.dylib $$(echo $$lib | rev | cut -d. -f4 | rev).dylib; \
	done

	for stuff in $(BUILD_STAGE)/icu4c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicu*.69.1.dylib $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicu*.69.1.dylib $(BUILD_STAGE)/icu4c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*; do \
		$(I_N_T) -change libicudata.69.dylib $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicudata.69.dylib $$stuff; \
		$(I_N_T) -change libicui18n.69.dylib $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicui18n.69.dylib $$stuff; \
		$(I_N_T) -change libicuio.69.dylib $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicuio.69.dylib $$stuff; \
		$(I_N_T) -change libicutest.69.dylib $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicutest.69.dylib $$stuff; \
		$(I_N_T) -change libicutu.69.dylib $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicutu.69.dylib $$stuff; \
		$(I_N_T) -change libicuuc.69.dylib $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicuuc.69.dylib $$stuff; \
	done
endif

icu4c-package: icu4c-stage
	# icu4c.mk Package Structure
	rm -rf $(BUILD_DIST)/libicu{69,-dev} \
		$(BUILD_DIST)/icu-devtools
	mkdir -p $(BUILD_DIST)/libicu{69,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libicu-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share \
		$(BUILD_DIST)/icu-devtools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# icu4c.mk Prep libicu69
	cp -a $(BUILD_STAGE)/icu4c/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libicu*.69*.dylib $(BUILD_DIST)/libicu69/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

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
	$(call SIGN,libicu69,general.xml)
	$(call SIGN,icu-devtools,general.xml)

	# icu4c.mk Make .debs
	$(call PACK,libicu69,DEB_ICU_V)
	$(call PACK,libicu-dev,DEB_ICU_V)
	$(call PACK,icu-devtools,DEB_ICU_V)

	# icu4c.mk Build cleanup
	rm -rf $(BUILD_DIST)/libicu{69,-dev} \
		$(BUILD_DIST)/icu-devtools

.PHONY: icu4c icu4c-package
