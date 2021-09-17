ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libuv1
LIBUV1_VERSION := 1.42.0
DEB_LIBUV1_V   ?= $(LIBUV1_VERSION)

libuv1-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://dist.libuv.org/dist/v$(LIBUV1_VERSION)/libuv-v$(LIBUV1_VERSION).tar.gz
	$(call EXTRACT_TAR,libuv-v$(LIBUV1_VERSION).tar.gz,libuv-v$(LIBUV1_VERSION),libuv1)

ifneq ($(wildcard $(BUILD_WORK)/libuv1/.build_complete),)
libuv1:
	@echo "Using previously built libuv1."
else
libuv1: libuv1-setup
	if ! [ -f $(BUILD_WORK)/libuv1/configure ]; then \
		cd $(BUILD_WORK)/libuv1 && ./autogen.sh; \
	fi
	cd $(BUILD_WORK)/libuv1 && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libuv1
	+$(MAKE) -C $(BUILD_WORK)/libuv1 install \
		DESTDIR="$(BUILD_STAGE)/libuv1"
	$(call AFTER_BUILD,copy)
endif

libuv1-package: libuv1-stage
	# libuv1.mk Package Structure
	rm -rf $(BUILD_DIST)/libuv1{,-dev}
	mkdir -p $(BUILD_DIST)/libuv1{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libuv1.mk Prep libuv1
	cp -a $(BUILD_STAGE)/libuv1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libuv.1.dylib $(BUILD_DIST)/libuv1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libuv1.mk Prep libuv1-dev
	cp -a $(BUILD_STAGE)/libuv1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libuv1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/libuv1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libuv.{a,dylib},pkgconfig} $(BUILD_DIST)/libuv1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libuv1.mk Sign
	$(call SIGN,libuv1,general.xml)

	# libuv1.mk Make .debs
	$(call PACK,libuv1,DEB_LIBUV1_V)
	$(call PACK,libuv1-dev,DEB_LIBUV1_V)

	# libuv1.mk Build cleanup
	rm -rf $(BUILD_DIST)/libuv1{,-dev}

.PHONY: libuv1 libuv1-package
