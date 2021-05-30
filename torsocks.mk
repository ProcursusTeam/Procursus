ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += torsocks
TORSOCKS_VERSION := 2.3.0
DEB_TORSOCKS_V   ?= $(TORSOCKS_VERSION)

torsocks-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://people.torproject.org/~dgoulet/torsocks/torsocks-$(TORSOCKS_VERSION).tar.xz{,.asc}
	$(call PGP_VERIFY,torsocks-$(TORSOCKS_VERSION).tar.xz,asc)
	$(call EXTRACT_TAR,torsocks-$(TORSOCKS_VERSION).tar.xz,torsocks-$(TORSOCKS_VERSION),torsocks)
	$(call DO_PATCH,torsocks,torsocks,-p1)

ifneq ($(wildcard $(BUILD_WORK)/torsocks/.build_complete),)
torsocks:
	@echo "Using previously built torsocks."
else
torsocks: torsocks-setup
	cd $(BUILD_WORK)/torsocks && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/torsocks \
		CFLAGS="$(CFLAGS) -DLIBIOSEXEC_INTERNAL" \
		CPPFLAGS="$(CPPFLAGS) -DLIBIOSEXEC_INTERNAL"
	+$(MAKE) -C $(BUILD_WORK)/torsocks install \
		DESTDIR=$(BUILD_STAGE)/torsocks
	mv $(BUILD_STAGE)/torsocks/$(MEMO_PREFIX)/etc/tor/torsocks.conf \
		$(BUILD_STAGE)/torsocks/$(MEMO_PREFIX)/etc/tor/torsocks.conf.sample
	touch $(BUILD_WORK)/torsocks/.build_complete
endif

torsocks-package: torsocks-stage
	# torsocks.mk Package Structure
	rm -rf $(BUILD_DIST)/torsocks
	
	# torsocks.mk Prep torsocks
	cp -a $(BUILD_STAGE)/torsocks $(BUILD_DIST)
	
	# torsocks.mk Sign
	$(call SIGN,torsocks,general.xml)
	
	# torsocks.mk Make .debs
	$(call PACK,torsocks,DEB_TORSOCKS_V)
	
	# torsocks.mk Build cleanup
	rm -rf $(BUILD_DIST)/torsocks

.PHONY: torsocks torsocks-package
