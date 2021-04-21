ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS          += transmission
TRANSMISSION_VERSION := 3.00
DEB_TRANSMISSION_V   ?= $(TRANSMISSION_VERSION)-1

transmission-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/transmission/transmission-releases/raw/master/transmission-$(TRANSMISSION_VERSION).tar.xz
	$(call EXTRACT_TAR,transmission-$(TRANSMISSION_VERSION).tar.xz,transmission-$(TRANSMISSION_VERSION),transmission)

ifneq ($(wildcard $(BUILD_WORK)/transmission/.build_complete),)
transmission:
	@echo "Using previously built transmission."
else
transmission: transmission-setup curl libevent
	cd $(BUILD_WORK)/transmission && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-debug \
		--enable-cli \
		--enable-daemon \
		--disable-mac \
		--disable-nls
	+$(MAKE) -C $(BUILD_WORK)/transmission
	+$(MAKE) -C $(BUILD_WORK)/transmission install \
		DESTDIR=$(BUILD_STAGE)/transmission
	touch $(BUILD_WORK)/transmission/.build_complete
endif

transmission-package: transmission-stage
	# transmission.mk Package Structure
	rm -rf $(BUILD_DIST)/transmission
	mkdir -p $(BUILD_DIST)/transmission

	# transmission.mk Prep transmission
	cp -a $(BUILD_STAGE)/transmission/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) $(BUILD_DIST)/transmission

	# transmission.mk Sign
	$(call SIGN,transmission,general.xml)

	# transmission.mk Make .debs
	$(call PACK,transmission,DEB_TRANSMISSION_V)

	# transmission.mk Build cleanup
	rm -rf $(BUILD_DIST)/transmission

.PHONY: transmission transmission-package
