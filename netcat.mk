ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += netcat
NETCAT_VERSION := 0.7.1
DEB_NETCAT_V   ?= $(NETCAT_VERSION)-2

netcat-setup: setup file-setup
	wget -q -nc -P $(BUILD_SOURCE) https://downloads.sourceforge.net/project/netcat/netcat/$(NETCAT_VERSION)/netcat-$(NETCAT_VERSION).tar.bz2
	$(call EXTRACT_TAR,netcat-$(NETCAT_VERSION).tar.bz2,netcat-$(NETCAT_VERSION),netcat)
	cp -a $(BUILD_WORK)/file/config.sub $(BUILD_WORK)/netcat

ifneq ($(wildcard $(BUILD_WORK)/netcat/.build_complete),)
netcat:
	@echo "Using previously built netcat."
else
netcat: netcat-setup gettext
	cd $(BUILD_WORK)/netcat && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/netcat install \
		DESTDIR="$(BUILD_STAGE)/netcat"
	rm -rf $(BUILD_STAGE)/netcat/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/info
	touch $(BUILD_WORK)/netcat/.build_complete
endif

netcat-package: netcat-stage
	# netcat.mk Package Structure
	rm -rf $(BUILD_DIST)/netcat
	mkdir -p $(BUILD_DIST)/netcat

	# netcat.mk Prep netcat
	cp -a $(BUILD_STAGE)/netcat/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) $(BUILD_DIST)/netcat

	# netcat.mk Sign
	$(call SIGN,netcat,general.xml)

	# netcat.mk Make .debs
	$(call PACK,netcat,DEB_NETCAT_V)

	# netcat.mk Build cleanup
	rm -rf $(BUILD_DIST)/netcat

.PHONY: netcat netcat-package
