ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += guile
GUILE_VERSION := 3.0.7
DEB_GUILE_V   ?= $(GUILE_VERSION)

guile-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftp.gnu.org/gnu/guile/guile-$(GUILE_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,guile-$(GUILE_VERSION).tar.gz)
	$(call EXTRACT_TAR,guile-$(GUILE_VERSION).tar.gz,guile-$(GUILE_VERSION),guile)

ifneq ($(wildcard $(BUILD_WORK)/guile/.build_complete),)
guile:
	@echo "Using previously built guile."
else
guile: guile-setup libgmp10 libunistring libgc libffi readline gettext libtool
	cd $(BUILD_WORK)/guile && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/guile
	+$(MAKE) -C $(BUILD_WORK)/guile install \
		DESTDIR=$(BUILD_STAGE)/guile
	+$(MAKE) -C $(BUILD_WORK)/guile install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/guile/.build_complete
endif

guile-package: guile-stage
	# guile.mk Package Structure
	rm -rf $(BUILD_DIST)/guile-3.0
	rm -rf $(BUILD_DIST)/guile-3.0{-dev,-libs}
	mkdir -p $(BUILD_DIST)/guile-3.0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/guile-3.0{-dev,-libs}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# guile.mk Prep guile-3.0
	cp -a $(BUILD_STAGE)/guile/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/guile $(BUILD_DIST)/guile-3.0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/guile/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1 $(BUILD_DIST)/guile-3.0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

        # guile.mk Prep guile-3.0-dev
	cp -a $(BUILD_STAGE)/guile/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/guile-{config,snarf,tools} $(BUILD_DIST)/guile-3.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/guile/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/guile-3.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/guile/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libguile-3.0.a $(BUILD_DIST)/guile-3.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/guile/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/guile-3.0.pc $(BUILD_DIST)/guile-3.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/guile/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/aclocal/guile.m4 $(BUILD_DIST)/guile-3.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/guile/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/guile/3.0/scripts $(BUILD_DIST)/guile-3.0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# guile.mk Prep guile-3.0-libs
	cp -a $(BUILD_STAGE)/guile/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/guile/3.0 $(BUILD_DIST)/guile-3.0-libs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/guile/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libguile{-3.0.1.dylib,-3.0.a-gdb.scm,-3.0.dylib,-3.0.la} $(BUILD_DIST)/guile-3.0-libs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/guile/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/guile/3.0/{guile-procedures.txt,ice-9,language,oop,rnrs,rnrs.scm,scheme,srfi,statprof.scm,sxml,system,texinfo,texinfo.scm,web} $(BUILD_DIST)/guile-3.0-libs/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# guile.mk Sign
	$(call SIGN,guile-3.0,general.xml)
	$(call SIGN,guile-3.0-dev,general.xml)
	$(call SIGN,guile-3.0-libs,general.xml)

	# guile.mk Make .debs
	$(call PACK,guile-3.0,DEB_GUILE_V)
	$(call PACK,guile-3.0-dev,DEB_GUILE_V)
	$(call PACK,guile-3.0-libs,DEB_GUILE_V)

	# guile.mk Build cleanup
	rm -rf $(BUILD_DIST)/guile-3.0 $(BUILD_DIST)/guile-3.0-dev $(BUILD_DIST)/guile-3.0-libs

.PHONY: guile guile-package
