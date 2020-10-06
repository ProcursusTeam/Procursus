ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  	+= nload
NLOAD_VERSION := 0.7.4
DEB_NLOAD_V   ?= $(NLOAD_VERSION)

nload-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/rolandriegel/nload/archive/v$(NLOAD_VERSION).tar.gz
	$(call EXTRACT_TAR,v$(NLOAD_VERSION).tar.gz,nload-$(NLOAD_VERSION),nload)
	$(call DO_PATCH,nload,nload,-p1)

ifneq ($(wildcard $(BUILD_WORK)/nload/.build_complete),)
nload:
	@echo "Using previously built nload."
else
nload: nload-setup
	cd $(BUILD_WORK)/nload &&./run_autotools && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking
	+$(MAKE) -C $(BUILD_WORK)/nload
	+$(MAKE) -C $(BUILD_WORK)/nload install \
		DESTDIR=$(BUILD_STAGE)/nload
	touch $(BUILD_WORK)/nload/.build_complete
endif

nload-package: nload-stage
	# nload.mk Package Structure
	rm -rf $(BUILD_DIST)/nload

	# nload.mk Prep nload
	cp -a $(BUILD_STAGE)/nload $(BUILD_DIST)

	# nload.mk Sign
	$(call SIGN,nload,general.xml)

	# nload.mk Make .debs
	$(call PACK,nload,DEB_NLOAD_V)

	# nload.mk Build cleanup
	rm -rf $(BUILD_DIST)/nload

.PHONY: nload nload-package
