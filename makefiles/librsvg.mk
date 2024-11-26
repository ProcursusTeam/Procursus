ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += librsvg
LIBRSVG_VERSION := 2.52.1
DEB_LIBRSVG_V   ?= $(LIBRSVG_VERSION)

librsvg-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://download.gnome.org/sources/librsvg/$(shell echo $(LIBRSVG_VERSION) | cut -f-2 -d.)/librsvg-$(LIBRSVG_VERSION).tar.xz
	$(call EXTRACT_TAR,librsvg-$(LIBRSVG_VERSION).tar.xz,librsvg-$(LIBRSVG_VERSION),librsvg)
	$(call DO_PATCH,librsvg,librsvg,-p1)
	sed -i "s|\PKG_CONFIG='\$$(PKG_CONFIG)'|$(DEFAULT_RUST_FLAGS) RUSTFLAGS='-L $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib'|g" $(BUILD_WORK)/librsvg/Makefile.am
	sed -i 's|cairo-rs = { version="0.14.0"|cairo-rs = { version="0.14.9"|g' $(BUILD_WORK)/librsvg/Cargo.toml
	sed -i "s|-framework Foundation|-framework Foundation -framework Security|g" $(BUILD_WORK)/librsvg/Makefile.am

ifneq ($(wildcard $(BUILD_WORK)/librsvg/.build_complete),)
librsvg:
	@echo "Using previously built librsvg."
else
librsvg: librsvg-setup glib2.0 gettext cairo gdk-pixbuf pango
	cd $(BUILD_WORK)/librsvg && cargo vendor
	cd $(BUILD_WORK)/librsvg && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-Bsymbolic \
		--enable-introspection=no \
		--enable-vala=no \
		--enable-pixbuf-loader \
		--with-sysroot=$(BUILD_BASE) \
		PROFILE=release \
		RUST_TARGET=$(RUST_TARGET)
	+$(MAKE) -C $(BUILD_WORK)/librsvg
	+$(MAKE) -C $(BUILD_WORK)/librsvg install \
		DESTDIR=$(BUILD_STAGE)/librsvg
	$(call AFTER_BUILD,copy)
endif

librsvg-package: librsvg-stage
# librsvg.mk Package Structure
	rm -rf $(BUILD_DIST)/librsvg2-{2,bin,common,dev}
	mkdir -p $(BUILD_DIST)/librsvg2-2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/librsvg2-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/gdk-pixbuf-2.0/2.10.0/loaders,share} \
		$(BUILD_DIST)/librsvg2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib/{pkgconfig,gdk-pixbuf-2.0/2.10.0/loaders},include} \
		$(BUILD_DIST)/librsvg2-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	
# librsvg.mk Prep librsvg2-2
	cp -a $(BUILD_STAGE)/librsvg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/librsvg-2.2.dylib \
		$(BUILD_DIST)/librsvg2-2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

# librsvg.mk Prep librsvg2-common
	cp -a $(BUILD_STAGE)/librsvg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader-svg.so \
		$(BUILD_DIST)/librsvg2-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/gdk-pixbuf-2.0/2.10.0/loaders
	cp -a $(BUILD_STAGE)/librsvg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/thumbnailers \
		$(BUILD_DIST)/librsvg2-common/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

# librsvg.mk Prep librsvg2-dev
	cp -a $(BUILD_STAGE)/librsvg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(gdk-pixbuf-2.0|librsvg-2.2.dylib) \
		$(BUILD_DIST)/librsvg2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/librsvg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader-svg.a \
		$(BUILD_DIST)/librsvg2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/gdk-pixbuf-2.0/2.10.0/loaders
	cp -a $(BUILD_STAGE)/librsvg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/librsvg-2.0 \
		$(BUILD_DIST)/librsvg2-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include

# librsvg.mk Prep librsvg2-bin
	cp -a $(BUILD_STAGE)/librsvg/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/rsvg-convert \
		$(BUILD_DIST)/librsvg2-bin/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	
# librsvg.mk Sign
	$(call SIGN,librsvg2-2,general.xml)
	$(call SIGN,librsvg2-common,general.xml)
	$(call SIGN,librsvg2-bin,general.xml)
	
# librsvg.mk Make .debs
	$(call PACK,librsvg2-2,DEB_LIBRSVG_V)
	$(call PACK,librsvg2-common,DEB_LIBRSVG_V)
	$(call PACK,librsvg2-dev,DEB_LIBRSVG_V)
	$(call PACK,librsvg2-bin,DEB_LIBRSVG_V)

# librsvg.mk Build cleanup
	rm -rf $(BUILD_DIST)/librsvg2-{2,bin,common,dev}

.PHONY: librsvg librsvg-package