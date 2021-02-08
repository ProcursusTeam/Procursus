ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += util-macros
UTILMACROS_VERSION := 1.19.2
DEB_UTILMACROS_V   ?= $(UTILMACROS_VERSION)

util-macros-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://xorg.freedesktop.org/releases/individual/util/util-macros-$(UTILMACROS_VERSION).tar.bz2{,.sig}   
	$(call PGP_VERIFY,util-macros-$(UTILMACROS_VERSION).tar.bz2)
	$(call EXTRACT_TAR,util-macros-$(UTILMACROS_VERSION).tar.bz2,util-macros-$(UTILMACROS_VERSION),util-macros)

ifneq ($(wildcard $(BUILD_WORK)/util-macros/.build_complete),)
util-macros:
	@echo "Using previously built util-macros."
else
util-macros: util-macros-setup
	cd $(BUILD_WORK)/util-macros && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--sysconfdir=/etc \
		--localstatedir=/var \
		--disable-static
	+$(MAKE) -C $(BUILD_WORK)/util-macros
	+$(MAKE) -C $(BUILD_WORK)/util-macros install \
		DESTDIR=$(BUILD_STAGE)/util-macros
	+$(MAKE) -C $(BUILD_WORK)/util-macros install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/util-macros/.build_complete
endif


util-macros-package: util-macros-stage
	rm -rf $(BUILD_DIST)/xorg-util-macros
	mkdir -p $(BUILD_DIST)/xorg-util-macros
	
	# util-macros.mk Prep util-macros
	cp -a $(BUILD_STAGE)/util-macros/usr $(BUILD_DIST)/xorg-util-macros

	# util-macros.mk Sign
	$(call SIGN,xorg-util-macros,general.xml)
	
	# util-macros.mk Make .debs
	$(call PACK,xorg-util-macros,DEB_UTILMACROS_V)
	
	# util-macros.mk Build cleanup
	rm -rf $(BUILD_DIST)/xorg-util-macros

.PHONY: util-macros util-macros-package
