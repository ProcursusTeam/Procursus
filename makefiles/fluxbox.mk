ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += fluxbox
FLUXBOX_VERSION := 1.3.7
DEB_FLUXBOX_V   ?= $(FLUXBOX_VERSION)

fluxbox-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) http://sourceforge.net/projects/fluxbox/files/fluxbox/$(FLUXBOX_VERSION)/fluxbox-$(FLUXBOX_VERSION).tar.xz
	$(call EXTRACT_TAR,fluxbox-$(FLUXBOX_VERSION).tar.xz,fluxbox-$(FLUXBOX_VERSION),fluxbox)
	$(call DO_PATCH,fluxbox,fluxbox,-p1)
	$(SED) -i -e '/AC_FUNC_MALLOC/d' -e '/AC_FUNC_REALLOC/d' $(BUILD_WORK)/fluxbox/configure.ac

ifneq ($(wildcard $(BUILD_WORK)/fluxbox/.build_complete),)
fluxbox:
	@echo "Using previously built fluxbox."
else
fluxbox: fluxbox-setup imlib2 libx11 libxext libxft libxinerama libxpm libxrandr libxrender fontconfig freetype libfribidi
	cd $(BUILD_WORK)/fluxbox && autoreconf -fi
	cd $(BUILD_WORK)/fluxbox && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	$(SED) -i s/HAVE_MACH_ABSOLUTE_TIME/HAVE_MACH_ABSOLUTELY_NO_TIME/ $(BUILD_WORK)/fluxbox/config.h
	+$(MAKE) -C $(BUILD_WORK)/fluxbox
	+$(MAKE) -C $(BUILD_WORK)/fluxbox install \
		DESTDIR=$(BUILD_STAGE)/fluxbox
	touch $(BUILD_WORK)/fluxbox/.build_complete
endif

fluxbox-package: fluxbox-stage
	# fluxbox.mk Package Structure
	rm -rf $(BUILD_DIST)/fluxbox
	mkdir -p $(BUILD_DIST)/fluxbox
	
	# fluxbox.mk Prep fluxbox
	cp -a $(BUILD_STAGE)/fluxbox $(BUILD_DIST)
	
	# fluxbox.mk Sign
	$(call SIGN,fluxbox,general.xml)
	
	# fluxbox.mk Make .debs
	$(call PACK,fluxbox,DEB_FLUXBOX_V)
	
	# fluxbox.mk Build cleanup
	rm -rf $(BUILD_DIST)/fluxbox

.PHONY: fluxbox fluxbox-package
