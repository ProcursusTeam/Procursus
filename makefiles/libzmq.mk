ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += libzmq
LIBZMQ_VERSION := 4.3.4
DEB_LIBZMQ_V   ?= $(LIBZMQ_VERSION)

libzmq-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/zeromq/libzmq/releases/download/v$(LIBZMQ_VERSION)/zeromq-$(LIBZMQ_VERSION).tar.gz
	$(call EXTRACT_TAR,zeromq-$(LIBZMQ_VERSION).tar.gz,zeromq-$(LIBZMQ_VERSION),libzmq)

ifneq ($(wildcard $(BUILD_WORK)/libzmq/.build_complete),)
libzmq:
	@echo "Using previously built libzmq."
else
libzmq: libzmq-setup libsodium
	cd $(BUILD_WORK)/libzmq && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-libsodium
	+$(MAKE) -C $(BUILD_WORK)/libzmq
	+$(MAKE) -C $(BUILD_WORK)/libzmq install \
		DESTDIR=$(BUILD_STAGE)/libzmq
	+$(MAKE) -C $(BUILD_WORK)/libzmq install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libzmq/.build_complete
endif

libzmq-package: libzmq-stage
	# libzmq.mk Package Structure
	rm -rf $(BUILD_DIST)/libzmq{-dev,5}
	mkdir -p $(BUILD_DIST)/libzmq-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libzmq5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libzmq.mk Prep libzmq5
	cp -a $(BUILD_STAGE)/libzmq/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libzmq.5.dylib $(BUILD_DIST)/libzmq5/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libzmq.mk Prep libzmq-dev
	cp -a $(BUILD_STAGE)/libzmq/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libzmq.5.dylib) $(BUILD_DIST)/libzmq-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libzmq/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libzmq-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include
	cp -a $(BUILD_STAGE)/libzmq/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/libzmq-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# libzmq.mk Sign
	$(call SIGN,libzmq5,general.xml)
	$(call SIGN,libzmq-dev,general.xml)

	# libzmq.mk Make .debs
	$(call PACK,libzmq5,DEB_LIBZMQ_V)
	$(call PACK,libzmq-dev,DEB_LIBZMQ_V)

	# libzmq.mk Build cleanup
	rm -rf $(BUILD_DIST)/libzmq{-dev,5}

.PHONY: libzmq libzmq-package
