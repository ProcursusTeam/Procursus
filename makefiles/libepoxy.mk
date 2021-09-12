ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += libepoxy
LIBEPOXY_VERSION := 1.5.7
DEB_LIBEPOXY_V   ?= $(LIBEPOXY_VERSION)

libepoxy-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://download.gnome.org/sources/libepoxy/$(shell echo $(LIBEPOXY_VERSION) | cut -d. -f-2)/libepoxy-$(LIBEPOXY_VERSION).tar.xz
	$(call EXTRACT_TAR,libepoxy-$(LIBEPOXY_VERSION).tar.xz,libepoxy-$(LIBEPOXY_VERSION),libepoxy)
	mkdir -p $(BUILD_WORK)/libepoxy/build
	echo -e "$(DEFAULT_MESON_CROSS_TXT)" > $(BUILD_WORK)/libepoxy/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/libepoxy/.build_complete),)
libepoxy:
	@echo "Using previously built libepoxy."
else
libepoxy: libepoxy-setup libx11 mesa
	$(call MESON_NINJA_INSTALL,libepoxy,\
		-Dtests=false \
		-Dx11=true \
 		-Dglx=yes \
		 ..)
	$(call AFTER_BUILD,copy)
endif

libepoxy-package: libepoxy-stage
	rm -rf $(BUILD_DIST)/libepoxy{0,-dev}
	mkdir -p $(BUILD_DIST)/libepoxy{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	#libepoxy.mk Prep libepxoy0
	cp -a $(BUILD_STAGE)/libepoxy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libepoxy.0.dylib $(BUILD_DIST)/libepoxy0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libepoxy.mk Prep libepoxy-dev
	cp -a $(BUILD_STAGE)/libepoxy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libepoxy.0.dylib) $(BUILD_DIST)/libepoxy-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libepoxy/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libepoxy-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libepoxy.mk Sign
	$(call SIGN,libepoxy0,general.xml)

	# libepoxy.mk Make .debs
	$(call PACK,libepoxy0,DEB_LIBEPOXY_V)
	$(call PACK,libepoxy-dev,DEB_LIBEPOXY_V)

	# libepoxy.mk Build cleanup
	rm -rf $(BUILD_DIST)/libepoxy{0,-dev}

.PHONY: libepoxy libepoxy-package
