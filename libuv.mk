ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libuv
LIBUV_VERSION := 1.38.1
DEB_LIBUV_V   ?= $(LIBUV_VERSION)

libuv-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://dist.libuv.org/dist/v$(LIBUV_VERSION)/libuv-v$(LIBUV_VERSION).tar.gz
	$(call EXTRACT_TAR,libuv-v$(LIBUV_VERSION).tar.gz,libuv-v$(LIBUV_VERSION),libuv)

ifneq ($(wildcard $(BUILD_WORK)/libuv/.build_complete),)
libuv:
	@echo "Using previously built libuv."
else
libuv: libuv-setup
	if ! [ -f $(BUILD_WORK)/libuv/configure ]; then \
		cd $(BUILD_WORK)/libuv && ./autogen.sh; \
	fi
	cd $(BUILD_WORK)/libuv && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libuv
	+$(MAKE) -C $(BUILD_WORK)/libuv install \
		DESTDIR="$(BUILD_STAGE)/libuv"
	+$(MAKE) -C $(BUILD_WORK)/libuv install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/libuv/.build_complete
endif

libuv-package: libuv-stage
	# libuv.mk Package Structure
	rm -rf $(BUILD_DIST)/libuv
	mkdir -p $(BUILD_DIST)/libuv
	
	# libuv.mk Prep libuv
	cp -a $(BUILD_STAGE)/libuv/usr $(BUILD_DIST)/libuv
	
	# libuv.mk Sign
	$(call SIGN,libuv,general.xml)
	
	# libuv.mk Make .debs
	$(call PACK,libuv,DEB_LIBUV_V)
	
	# libuv.mk Build cleanup
	rm -rf $(BUILD_DIST)/libuv

.PHONY: libuv libuv-package
