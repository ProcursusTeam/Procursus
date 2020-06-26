ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += xz
XZ_VERSION    := 5.2.5
DEB_XZ_V      ?= $(XZ_VERSION)

xz-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://tukaani.org/xz/xz-$(XZ_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,xz-$(XZ_VERSION).tar.xz)
	$(call EXTRACT_TAR,xz-$(XZ_VERSION).tar.xz,xz-$(XZ_VERSION),xz)
	mkdir -p $(BUILD_STAGE)/xz/usr/bin

ifneq ($(wildcard $(BUILD_WORK)/xz/.build_complete),)
xz:
	@echo "Using previously built xz."
else
xz: xz-setup
	cd $(BUILD_WORK)/xz && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr/local \
		--disable-debug \
		--disable-dependency-tracking \
		--disable-silent-rules
	+$(MAKE) -C $(BUILD_WORK)/xz
	+$(MAKE) -C $(BUILD_WORK)/xz install \
		DESTDIR=$(BUILD_STAGE)/xz
	+$(MAKE) -C $(BUILD_WORK)/xz install \
		DESTDIR=$(BUILD_BASE)
	for bin in $(BUILD_STAGE)/xz/usr/local/bin/*; do \
		ln -s ../local/bin/$$(basename $$bin) $(BUILD_STAGE)/xz/usr/bin/$$(basename $$bin); \
	done
	touch $(BUILD_WORK)/xz/.build_complete
endif

xz-package: xz-stage
	# xz.mk Package Structure
	rm -rf $(BUILD_DIST)/xz-utils
	mkdir -p $(BUILD_DIST)/xz-utils
	
	# xz.mk Prep xz-utils
	cp -a $(BUILD_STAGE)/xz/usr $(BUILD_DIST)/xz-utils
	
	# xz.mk Sign
	$(call SIGN,xz-utils,general.xml)
	
	# xz.mk Make .debs
	$(call PACK,xz-utils,DEB_XZ_V)
	
	# xz.mk Build cleanup
	rm -rf $(BUILD_DIST)/xz-utils

.PHONY: xz xz-package
