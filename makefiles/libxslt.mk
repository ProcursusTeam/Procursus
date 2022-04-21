ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += libxslt
LIBXSLT_VERSION := 1.1.35
DEB_LIBXSLT_V   ?= $(LIBXSLT_VERSION)

### Provided by macOS/iOS and only used for tools. Try not to link anything to this.

libxslt-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://download.gnome.org/sources/libxslt/1.1/libxslt-$(LIBXSLT_VERSION).tar.xz
	$(call EXTRACT_TAR,libxslt-$(LIBXSLT_VERSION).tar.xz,libxslt-$(LIBXSLT_VERSION),libxslt)

ifneq ($(wildcard $(BUILD_WORK)/libxslt/.build_complete),)
libxslt:
	@echo "Using previously built libxslt."
else
libxslt: libxslt-setup libxml2
	# Can build on macOS, but for others, making pkgconfigs for system libxml2 is needed (since only tbds provided by SDK)
	# Make sure libhistory or other stuff not included so that xsltproc can just use system provided libxslt/libxml2 without extra deps
	cd $(BUILD_WORK)/libxslt && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--libdir=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib \
		--with-html-subdir=libxslt1-dev/html \
		--without-python \
		--without-crypto
	+$(MAKE) -C $(BUILD_WORK)/libxslt \
		LDFLAGS="-no-undefined"
	+$(MAKE) -C $(BUILD_WORK)/libxslt install \
		DESTDIR=$(BUILD_STAGE)/libxslt
	for libs in xslt.1 exslt.0 xml2.2; do \
		$(I_N_T) -change $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib/lib$${libs}.dylib /usr/lib/lib$${libs}.dylib $(BUILD_STAGE)/libxslt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/xsltproc \
	done
	$(call AFTER_BUILD)
endif

libxslt-package: libxslt-stage
	# libxslt.mk Package Structure
	rm -rf $(BUILD_DIST)/{libxslt1{.1,-dev},xsltproc}
	mkdir -p $(BUILD_DIST)/libxslt1{.1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{$(MEMO_ALT_PREFIX)/lib,share/man}
	mkdir -p $(BUILD_DIST)/xsltproc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man}

	# libxslt.mk Prep libxslt1.1
	cp -a $(BUILD_STAGE)/libxslt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib/lib{xslt.1,exslt.0}.dylib $(BUILD_DIST)/libxslt1.1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib

	# libxslt.mk Prep libxslt1-dev
	mkdir -p $(BUILD_DIST)/libxslt1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/libxslt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib/{lib{,e}xslt.dylib,pkgconfig,xsltConf.sh} $(BUILD_DIST)/libxslt1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)$(MEMO_ALT_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libxslt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/xslt-config $(BUILD_DIST)/libxslt1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/libxslt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libxslt1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libxslt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{aclocal,doc} $(BUILD_DIST)/libxslt1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	cp -a $(BUILD_STAGE)/libxslt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 $(BUILD_DIST)/libxslt1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# libxslt.mk Prep xsltproc
	cp -a $(BUILD_STAGE)/libxslt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/xsltproc $(BUILD_STAGE)/xsltproc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/libxslt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 $(BUILD_STAGE)/xsltproc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man

	# libxslt.mk Sign
	$(call SIGN,libxslt1.1,general.xml)
	$(call SIGN,xsltproc,general.xml)

	# libxslt.mk Make .debs
	$(call PACK,libxslt1.1,DEB_LIBXSLT_V)
	$(call PACK,libxslt1-dev,DEB_LIBXSLT_V)
	$(call PACK,xsltproc,DEB_LIBXSLT_V)

	# libxslt.mk Build cleanup
	rm -rf $(BUILD_DIST)/{libxslt1{.1,-dev},xsltproc}

.PHONY: libxslt libxslt-package
