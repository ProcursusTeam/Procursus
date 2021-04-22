ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += gobject-introspection
GOBJECT-INTROSPECTION_VERSION := 1.60.2
DEB_GOBJECT-INTROSPECTION_V   ?= $(GOBJECT-INTROSPECTION_VERSION)

gobject-introspection-setup: setup bison glib2.0
	wget -q -nc -P$(BUILD_SOURCE) https://download-fallback.gnome.org/sources/gobject-introspection/1.60/gobject-introspection-1.60.2.tar.xz
	$(call EXTRACT_TAR,gobject-introspection-$(GOBJECT-INTROSPECTION_VERSION).tar.xz,gobject-introspection-$(GOBJECT-INTROSPECTION_VERSION),gobject-introspection)

ifneq ($(wildcard $(BUILD_WORK)/gobject-introspection/.build_complete),)
gobject-introspection:
	@echo "Using previously built gobject-introspection."
else
gobject-introspection: gobject-introspection-setup libx11 mesa
	cd $(BUILD_WORK)/gobject-introspection && ./autogen.sh -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/gobject-introspection
	+$(MAKE) -C $(BUILD_WORK)/gobject-introspection install \
		DESTDIR=$(BUILD_STAGE)/gobject-introspection
	+$(MAKE) -C $(BUILD_WORK)/gobject-introspection install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/gobject-introspection/.build_complete
endif

gobject-introspection-package: gobject-introspection-stage
	# gobject-introspection.mk Package Structure
	rm -rf $(BUILD_DIST)/gobject-introspection
	mkdir -p $(BUILD_DIST)/gobject-introspection
	
	# gobject-introspection.mk Prep gobject-introspection
	cp -a $(BUILD_STAGE)/gobject-introspection $(BUILD_DIST)
	
	# gobject-introspection.mk Sign
	$(call SIGN,gobject-introspection,general.xml)
	
	# gobject-introspection.mk Make .debs
	$(call PACK,gobject-introspection,DEB_GOBJECT-INTROSPECTION_V)
	
	# gobject-introspection.mk Build cleanup
	rm -rf $(BUILD_DIST)/gobject-introspection

.PHONY: gobject-introspection gobject-introspection-package

