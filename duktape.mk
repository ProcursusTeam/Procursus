ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += duktape
DUKTAPE_VERSION := 2.6.0
DEB_DUKTAPE_V   ?= $(DUKTAPE_VERSION)

duktape-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/svaarala/duktape/releases/download/v$(DUKTAPE_VERSION)/duktape-$(DUKTAPE_VERSION).tar.xz
	$(call EXTRACT_TAR,duktape-$(DUKTAPE_VERSION).tar.xz,duktape-$(DUKTAPE_VERSION),duktape)
	$(SED) -i 's/gcc/cc/g' $(BUILD_WORK)/duktape/Makefile.cmdline
	$(SED) -i 's/gcc/cc/g' $(BUILD_WORK)/duktape/Makefile.sharedlibrary
	$(SED) -i 's|\$$(CCLIBS)|\$$(CCLIBS) $(LDFLAGS) $(CFLAGS)|g' $(BUILD_WORK)/duktape/Makefile.cmdline
	$(SED) -i 's|\$$(CC)|\$$(CC) $(LDFLAGS) $(CFLAGS)|g' $(BUILD_WORK)/duktape/Makefile.sharedlibrary
	mkdir -p $(BUILD_STAGE)/duktape/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/pkgconfig,include}
	cp $(BUILD_MISC)/duktape/duktape.pc $(BUILD_STAGE)/duktape/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/duktape.pc
	$(SED) -i 's|prefix=|prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)|g' \
		$(BUILD_STAGE)/duktape/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/duktape.pc
	$(SED) -i 's/Version:/Version: $(DUKTAPE_VERSION)/g' \
		$(BUILD_STAGE)/duktape/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/duktape.pc


ifneq ($(wildcard $(BUILD_WORK)/duktape/.build_complete),)
duktape:
	@echo "Using previously built duktape."
else
duktape: duktape-setup
	cd $(BUILD_WORK)/duktape && python2 tools/configure.py --output-directory \
		$(BUILD_STAGE)/duktape/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include -UDUK_USE_ES6_PROXY
	+$(MAKE) -C $(BUILD_WORK)/duktape -f Makefile.sharedlibrary install \
		INSTALL_PREFIX="$(BUILD_STAGE)/duktape/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"
	+$(MAKE) -C $(BUILD_WORK)/duktape -f Makefile.cmdline
	mkdir -p $(BUILD_STAGE)/duktape/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_WORK)/duktape/duk $(BUILD_STAGE)/duktape/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/duk
	cp -a $(BUILD_STAGE)/duktape/* $(BUILD_BASE)
	touch $(BUILD_WORK)/duktape/.build_complete
endif

duktape-package: duktape-stage
	# duktape.mk Package Structure
	rm -rf $(BUILD_DIST)/{libduktape206,duktape,duktape-dev}
	mkdir -p $(BUILD_DIST)/duktape/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
		$(BUILD_DIST)/duktape-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/pkgconfig,include,share/duktape} \
		$(BUILD_DIST)/libduktape206/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# duktape.mk Prep duktape
	cp -a $(BUILD_STAGE)/duktape/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/duk \
		$(BUILD_DIST)/duktape/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/duk

	# duktape.mk Prep duktape-dev
	cp -a $(BUILD_STAGE)/duktape/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/{duk_config.h,duktape.h} \
		$(BUILD_DIST)/duktape-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/duktape/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
		$(BUILD_DIST)/duktape-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/duktape
	cp -a $(BUILD_STAGE)/duktape/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libduktaped{.so,.206.so,.206.20600.so},pkgconfig} \
		$(BUILD_DIST)/duktape-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# duktape.mk Prep libduktape206
	cp -a $(BUILD_STAGE)/duktape/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libduktape{.so,.206.so,.206.20600.so} \
		$(BUILD_DIST)/libduktape206/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# duktape.mk Sign
	$(call SIGN,duktape,general.xml)
	$(call SIGN,libduktape206,general.xml)

	# duktape.mk Make .debs
	$(call PACK,duktape,DEB_DUKTAPE_V)
	$(call PACK,duktape-dev,DEB_DUKTAPE_V)
	$(call PACK,libduktape206,DEB_DUKTAPE_V)

	# duktape.mk Build cleanup
	rm -rf $(BUILD_DIST)/{libduktape206,duktape,duktape-dev}

.PHONY: duktape duktape-package
