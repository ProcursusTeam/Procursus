ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS   += gettext
GETTEXT_VERSION := 0.21
DEB_GETTEXT_V   ?= $(GETTEXT_VERSION)-4

gettext-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/gettext/gettext-$(GETTEXT_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,gettext-$(GETTEXT_VERSION).tar.xz)
	$(call EXTRACT_TAR,gettext-$(GETTEXT_VERSION).tar.xz,gettext-$(GETTEXT_VERSION),gettext)

ifneq ($(wildcard $(BUILD_WORK)/gettext/.build_complete),)
gettext:
	@echo "Using previously built gettext."
else
gettext: .SHELLFLAGS=-O extglob -c
gettext: gettext-setup ncurses libunistring
	cd $(BUILD_WORK)/gettext && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-java \
		--disable-csharp \
		--without-libintl-prefix
	+$(MAKE) -C $(BUILD_WORK)/gettext \
		LIBTERMINFO=-lncursesw \
		LTLIBTERMINFO=-lncursesw
	+$(MAKE) -C $(BUILD_WORK)/gettext install \
		DESTDIR=$(BUILD_STAGE)/gettext
	+$(MAKE) -C $(BUILD_WORK)/gettext install \
		DESTDIR=$(BUILD_BASE)
	rm -rf $(BUILD_STAGE)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/gettext-*
	touch $(BUILD_WORK)/gettext/.build_complete
endif

gettext-package: gettext-stage
	# gettext.mk Package Structure
	rm -rf $(BUILD_DIST)/gettext{,-base} \
		$(BUILD_DIST)/autopoint \
		$(BUILD_DIST)/libintl{8,-dev} \
		$(BUILD_DIST)/libtextstyle{0v5,-dev} \
		$(BUILD_DIST)/libgettextpo{0,-dev}
	mkdir -p $(BUILD_DIST)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib,share/{aclocal,man/man1,gettext}} \
		$(BUILD_DIST)/gettext-base/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1} \
		$(BUILD_DIST)/autopoint/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/{man/man1,gettext}} \
		$(BUILD_DIST)/libintl8/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libintl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,include} \
		$(BUILD_DIST)/libtextstyle{0v5,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libtextstyle-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include \
		$(BUILD_DIST)/libgettextpo{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libgettextpo-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# gettext.mk Prep gettext
	cp -a $(BUILD_STAGE)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{msg*,gettextize,recode-sr-latin,xgettext} $(BUILD_DIST)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libgettext{lib,src}-0.21.dylib,gettext} $(BUILD_DIST)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgettextlib.a $(BUILD_DIST)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/aclocal/!(host-cpu-c-abi.m4) $(BUILD_DIST)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/aclocal
	cp -a $(BUILD_STAGE)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/gettext/!(archive.dir.tar.xz) $(BUILD_DIST)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/gettext
	cp -a $(BUILD_STAGE)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/{msg*.1,gettextize.1,recode-sr-latin.1,xgettext.1} $(BUILD_DIST)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/

	# gettext.mk Prep gettext-base
	cp -a $(BUILD_STAGE)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/{envsubst,gettext{,.sh},ngettext} $(BUILD_DIST)/gettext-base/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/{envsubst,gettext,ngettext}.1 $(BUILD_DIST)/gettext-base/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man3 $(BUILD_DIST)/gettext-base/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/

	# gettext.mk Prep autopoint
	cp -a $(BUILD_STAGE)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/autopoint $(BUILD_DIST)/autopoint/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp -a $(BUILD_STAGE)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/autopoint.1 $(BUILD_DIST)/autopoint/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	cp -a $(BUILD_STAGE)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/gettext/archive.dir.tar.xz $(BUILD_DIST)/autopoint/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/gettext

	# gettext.mk Prep libintl8
	cp -a $(BUILD_STAGE)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libintl.8.dylib $(BUILD_DIST)/libintl8/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# gettext.mk Prep libintl-dev
	cp -a $(BUILD_STAGE)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libintl.{dylib,a} $(BUILD_DIST)/libintl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/libintl.h $(BUILD_DIST)/libintl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# gettext.mk Prep libtextstyle0v5
	cp -a $(BUILD_STAGE)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtextstyle.0.dylib $(BUILD_DIST)/libtextstyle0v5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# gettext.mk Prep libtextstyle-dev
	cp -a $(BUILD_STAGE)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtextstyle.{dylib,a} $(BUILD_DIST)/libtextstyle-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/textstyle{,.h} $(BUILD_DIST)/libtextstyle-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# gettext.mk Prep libgettextpo0
	cp -a $(BUILD_STAGE)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgettextpo.0.dylib $(BUILD_DIST)/libgettextpo0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# gettext.mk Prep libgettextpo-dev
	cp -a $(BUILD_STAGE)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libgettextpo.{dylib,a} $(BUILD_DIST)/libgettextpo-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/gettext/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/gettext-po.h $(BUILD_DIST)/libgettextpo-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

	# gettext.mk Sign
	$(call SIGN,gettext,general.xml)
	$(call SIGN,gettext-base,general.xml)
	$(call SIGN,libintl8,general.xml)
	$(call SIGN,libtextstyle0v5,general.xml)
	$(call SIGN,libgettextpo0,general.xml)

	# gettext.mk Make .debs
	$(call PACK,gettext,DEB_GETTEXT_V)
	$(call PACK,gettext-base,DEB_GETTEXT_V)
	$(call PACK,autopoint,DEB_GETTEXT_V)
	$(call PACK,libintl8,DEB_GETTEXT_V)
	$(call PACK,libintl-dev,DEB_GETTEXT_V)
	$(call PACK,libtextstyle0v5,DEB_GETTEXT_V)
	$(call PACK,libtextstyle-dev,DEB_GETTEXT_V)
	$(call PACK,libgettextpo0,DEB_GETTEXT_V)
	$(call PACK,libgettextpo-dev,DEB_GETTEXT_V)

	# gettext.mk Build cleanup
	rm -rf $(BUILD_DIST)/gettext{,-base} \
		$(BUILD_DIST)/autopoint \
		$(BUILD_DIST)/libintl{8,-dev} \
		$(BUILD_DIST)/libtextstyle{0v5,-dev} \
		$(BUILD_DIST)/libgettextpo{0,-dev}

.PHONY: gettext gettext-package
