ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += radare2
RADARE2_VERSION := 4.5.0
DEB_RADARE2_V   ?= $(RADARE2_VERSION)

radare2-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/radareorg/radare2/releases/download/$(RADARE2_VERSION)/radare2-src-$(RADARE2_VERSION).tar.gz
	$(call EXTRACT_TAR,radare2-src-$(RADARE2_VERSION).tar.gz,radare2-$(RADARE2_VERSION),radare2)

ifneq ($(wildcard $(BUILD_WORK)/radare2/.build_complete),)
radare2:
	@echo "Using previously built radare2."
else
radare2: radare2-setup libuv
	cd $(BUILD_WORK)/radare2 && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/radare2
	+$(MAKE) -C $(BUILD_WORK)/radare2 install \
		DESTDIR="$(BUILD_STAGE)/radare2"
	+$(MAKE) -C $(BUILD_WORK)/radare2 install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/radare2/.build_complete
endif

radare2-package: radare2-stage
	# radare2.mk Package Structure
	rm -rf $(BUILD_DIST)/radare2
	mkdir -p $(BUILD_DIST)/radare2
	
	# radare2.mk Prep radare2
	cp -a $(BUILD_STAGE)/radare2/usr $(BUILD_DIST)/radare2
	
	# radare2.mk Sign
	$(call SIGN,radare2,general.xml)
	
	# radare2.mk Make .debs
	$(call PACK,radare2,DEB_RADARE2_V)
	
	# radare2.mk Build cleanup
	rm -rf $(BUILD_DIST)/radare2

.PHONY: radare2 radare2-package
