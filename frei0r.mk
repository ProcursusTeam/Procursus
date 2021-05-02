ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += frei0r
FREI0R_VERSION := 1.7.0
DEB_FREI0R_V   ?= $(FREI0R_VERSION)-1

frei0r-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://files.dyne.org/frei0r/releases/frei0r-plugins-$(FREI0R_VERSION).tar.gz
	$(call EXTRACT_TAR,frei0r-plugins-$(FREI0R_VERSION).tar.gz,frei0r-plugins-$(FREI0R_VERSION),frei0r)

ifneq ($(wildcard $(BUILD_WORK)/frei0r/.build_complete),)
frei0r:
	@echo "Using previously built frei0r."
else
frei0r: frei0r-setup cairo
	cd $(BUILD_WORK)/frei0r && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DWITHOUT_OPENCV=ON \
		-DWITHOUT_GAVL=ON
	+$(MAKE) -C $(BUILD_WORK)/frei0r
	+$(MAKE) -C $(BUILD_WORK)/frei0r install \
		DESTDIR=$(BUILD_STAGE)/frei0r
	+$(MAKE) -C $(BUILD_WORK)/frei0r install \
		DESTDIR=$(BUILD_BASE)
	for file in $(BUILD_STAGE)/frei0r/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/frei0r-1/*.so ; do mv $$file "$${file%.*}.dylib" ; done
	touch $(BUILD_WORK)/frei0r/.build_complete
endif

frei0r-package: frei0r-stage
	# frei0r.mk Package Structure
	rm -rf $(BUILD_DIST)/frei0r-plugins{,-dev}
	mkdir -p $(BUILD_DIST)/frei0r-plugins{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# frei0r.mk Prep frei0r-plugins
	cp -a $(BUILD_STAGE)/frei0r/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/frei0r-1 $(BUILD_DIST)/frei0r-plugins/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# frei0r.mk Prep frei0r-plugins-dev
	cp -a $(BUILD_STAGE)/frei0r/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig $(BUILD_DIST)/frei0r-plugins-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/frei0r/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/frei0r-plugins-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# frei0r.mk Sign
	$(call SIGN,frei0r-plugins,general.xml)

	# frei0r.mk Make .debs
	$(call PACK,frei0r-plugins,DEB_FREI0R_V)
	$(call PACK,frei0r-plugins-dev,DEB_FREI0R_V)

	# frei0r.mk Build cleanup
	rm -rf $(BUILD_DIST)/frei0r-plugins{,-dev}

.PHONY: frei0r frei0r-package
