ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  	 += ccache
CCACHE_VERSION := 3.7.12
DEB_CCACHE_V   ?= $(CCACHE_VERSION)

ccache-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/ccache/ccache/releases/download/v$(CCACHE_VERSION)/ccache-$(CCACHE_VERSION).tar.xz
	$(call EXTRACT_TAR,ccache-$(CCACHE_VERSION).tar.xz,ccache-$(CCACHE_VERSION),ccache)

ifneq ($(wildcard $(BUILD_WORK)/ccache/.build_complete),)
ccache:
	@echo "Using previously built ccache."
else
ccache: ccache-setup
	cd $(BUILD_WORK)/ccache && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--mandir=/usr/share/man \
		--infodir=/usr/share/info \
		--sysconfdir=/etc
	+$(MAKE) -C $(BUILD_WORK)/ccache
	+$(MAKE) -C $(BUILD_WORK)/ccache install \
		DESTDIR="$(BUILD_STAGE)/ccache"
	touch $(BUILD_WORK)/ccache/.build_complete
endif

ccache-package: ccache-stage
	# ccache.mk Package Structure
	rm -rf $(BUILD_DIST)/ccache
	mkdir -p $(BUILD_DIST)/ccache

	# ccache.mk Prep ccache
	cp -a $(BUILD_STAGE)/ccache/usr $(BUILD_DIST)/ccache

	# ccache.mk Sign
	$(call SIGN,ccache,general.xml)

	# ccache.mk Make .debs
	$(call PACK,ccache,DEB_CCACHE_V)

	# ccache.mk Build cleanup
	rm -rf $(BUILD_DIST)/ccache

.PHONY: ccache ccache-package
