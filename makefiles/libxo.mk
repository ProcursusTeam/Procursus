ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libxo
LIBXO_VERSION := 1.4.0
DEB_LIBXO_V   ?= $(LIBXO_VERSION)

ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 2000 ] && echo 1),1)
LIBXO_LIBDIR  := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib
else
LIBXO_LIBDIR  := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
endif

# Provided by macOS 14/iOS 17+ and only used for tools and headers on said versions

libxo-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE), \
		https://github.com/Juniper/libxo/releases/download/$(LIBXO_VERSION)/libxo-$(LIBXO_VERSION).tar.gz)
	$(call EXTRACT_TAR,libxo-$(LIBXO_VERSION).tar.gz,libxo-$(LIBXO_VERSION),libxo)

ifneq ($(wildcard $(BUILD_WORK)/libxo/.build_complete),)
libxo:
	@echo "Using previously built libxo."
else
libxo: libxo-setup
	cd $(BUILD_WORK)/libxo && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-gettext=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--libdir=$(LIBXO_LIBDIR) \
		ac_cv_func_malloc_0_nonnull=yes \
		ac_cv_func_realloc_0_nonnull=yes
	+$(MAKE) -C $(BUILD_WORK)/libxo \
		LIBTOOL='$(BUILD_WORK)/libxo/libtool'
	+$(MAKE) -C $(BUILD_WORK)/libxo install \
		LIBTOOL='$(BUILD_WORK)/libxo/libtool' \
		DESTDIR=$(BUILD_STAGE)/libxo
ifeq ($(shell [ "$(CFVER_WHOLE)" -ge 2000 ] && echo 1),1)
	mkdir -p $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	# must use pc file from build misc because builtin lib prefix is always /usr
	$(INSTALL) -m644 $(BUILD_MISC)/libxo.pc $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig
	cp -a $(BUILD_STAGE)/libxo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	$(call AFTER_BUILD)
else
	$(call AFTER_BUILD,copy)
endif
endif

libxo-package: libxo-stage
	# libxo.mk Package Structure
	rm -rf $(BUILD_DIST)/libxo{0,-dev,-tools}
	mkdir -p $(BUILD_DIST)/libxo0/{$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man,$(LIBXO_LIBDIR)} \
		$(BUILD_DIST)/libxo-dev/{$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1},$(LIBXO_LIBDIR)} \
		$(BUILD_DIST)/libxo-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}

	# libxo.mk Prep libxo0
	cp -a $(BUILD_STAGE)/libxo/$(LIBXO_LIBDIR)/libxo{,.0.dylib} \
		$(BUILD_DIST)/libxo0/$(LIBXO_LIBDIR)
	rm -f $(BUILD_DIST)/libxo0/$(LIBXO_LIBDIR)/libxo/encoder/*.a \
		$(BUILD_DIST)/libxo0/$(LIBXO_LIBDIR)/libxo/**/*test*
	cp -a $(BUILD_STAGE)/libxo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man7 \
		$(BUILD_DIST)/libxo0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/

	# libxo.mk Prep libxo-dev
	cp -a $(BUILD_STAGE)/libxo/$(LIBXO_LIBDIR)/libxo{,.dylib,.a} \
		$(BUILD_STAGE)/libxo/$(LIBXO_LIBDIR)/pkgconfig \
		$(BUILD_DIST)/libxo-dev/$(LIBXO_LIBDIR)
	cp -a $(BUILD_STAGE)/libxo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
		$(BUILD_DIST)/libxo-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/
	rm -f $(BUILD_DIST)/libxo-dev/$(LIBXO_LIBDIR)/libxo/encoder/*.{enc,dylib} \
		$(BUILD_DIST)/libxo-dev/$(LIBXO_LIBDIR)/libxo/**/*test*
	cp -a $(BUILD_STAGE)/libxo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man{3,5} \
		$(BUILD_DIST)/libxo-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/
	cp -a $(BUILD_STAGE)/libxo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/xo{po,lint}.1$(MEMO_MANPAGE_SUFFIX) \
		$(BUILD_DIST)/libxo-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/libxo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{libxo-config,xo{po,lint}} \
		$(BUILD_DIST)/libxo-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

	# libxo.mk Prep libxo-tools
	cp -a $(BUILD_STAGE)/libxo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/xo{,html} \
		$(BUILD_DIST)/libxo-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/libxo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/xo{,html}.1$(MEMO_MANPAGE_SUFFIX) \
		$(BUILD_DIST)/libxo-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/
	cp -a $(BUILD_STAGE)/libxo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/libxo \
		$(BUILD_DIST)/libxo-tools/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/

	# libxo.mk Sign
	$(call SIGN,libxo0,general.xml)
	$(call SIGN,libxo-dev,general.xml)
	$(call SIGN,libxo-tools,general.xml)

	# libxo.mk Make .debs
	$(call PACK,libxo0,DEB_LIBXO_V)
	$(call PACK,libxo-dev,DEB_LIBXO_V)
	$(call PACK,libxo-tools,DEB_LIBXO_V)

	# libxo.mk Build cleanup
	rm -rf $(BUILD_DIST)/libxo{0,-dev,-tools}

.PHONY: libxo libxo-package
