ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += libevent
DOWNLOAD           += https://github.com/libevent/libevent/releases/download/release-$(LIBEVENT_VERSION)-stable/libevent-$(LIBEVENT_VERSION)-stable.tar.gz{,.asc}
LIBEVENT_VERSION   := 2.1.11
DEB_LIBEVENT_V     ?= $(LIBEVENT_VERSION)

libevent-setup: setup
	$(call PGP_VERIFY,libevent-$(LIBEVENT_VERSION)-stable.tar.gz,asc)
	$(call EXTRACT_TAR,libevent-$(LIBEVENT_VERSION)-stable.tar.gz,libevent-$(LIBEVENT_VERSION)-stable,libevent)

ifneq ($(wildcard $(BUILD_WORK)/libevent/.build_complete),)
libevent:
	@echo "Using previously built libevent."
else
libevent: libevent-setup openssl
	cd $(BUILD_WORK)/libevent && ./configure \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libevent install \
		DESTDIR=$(BUILD_STAGE)/libevent
	+$(MAKE) -C $(BUILD_WORK)/libevent install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libevent/.build_complete
endif

libevent-package: libevent-stage
	# libevent.mk Package Structure
	rm -rf $(BUILD_DIST)/libevent
	mkdir -p $(BUILD_DIST)/libevent
	
	# libevent.mk Prep libevent
	cp -a $(BUILD_STAGE)/libevent/usr $(BUILD_DIST)/libevent
	
	# libevent.mk Sign
	$(call SIGN,libevent,libevent.xml)
	
	# libevent.mk Make .debs
	$(call PACK,libevent,DEB_LIBEVENT_V)
	
	# libevent.mk Build cleanup
	rm -rf $(BUILD_DIST)/libevent

.PHONY: libevent libevent-package
