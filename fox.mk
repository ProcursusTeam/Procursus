ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += fox
FOX_VERSION := 1.6.56
DEB_FOX_V   ?= $(FOX_VERSION)

fox-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://fox-toolkit.org/ftp/fox-1.6.56.tar.gz
	$(call EXTRACT_TAR,fox-$(FOX_VERSION).tar.gz,fox-$(FOX_VERSION),fox)

ifneq ($(wildcard $(BUILD_WORK)/fox/.build_complete),)
fox:
	@echo "Using previously built fox."
else
fox: fox-setup slang2 glib2.0 gettext
	cd $(BUILD_WORK)/fox && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-x \
		--with-opengl=no \
		--with-xft
	+$(MAKE) -C $(BUILD_WORK)/fox
	+$(MAKE) -C $(BUILD_WORK)/fox install \
		DESTDIR=$(BUILD_STAGE)/fox
	+$(MAKE) -C $(BUILD_WORK)/fox install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/fox/.build_complete
endif

fox-package: fox-stage
# fox.mk Package Structure
	rm -rf $(BUILD_DIST)/fox
	
# fox.mk Prep fox
	cp -a $(BUILD_STAGE)/fox $(BUILD_DIST)
	
# fox.mk Sign
	$(call SIGN,fox,general.xml)
	
# fox.mk Make .debs
	$(call PACK,fox,DEB_FOX_V)
	
# fox.mk Build cleanup
	rm -rf $(BUILD_DIST)/fox

.PHONY: fox fox-package
