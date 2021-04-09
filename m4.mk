ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += m4
M4_VERSION  := 1.4.18
DEB_M4_V    ?= $(M4_VERSION)-1

m4-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/m4/m4-$(M4_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,m4-$(M4_VERSION).tar.gz)
	$(call EXTRACT_TAR,m4-$(M4_VERSION).tar.gz,m4-$(M4_VERSION),m4)
	$(call DO_PATCH,m4,m4,-p0)

ifneq ($(wildcard $(BUILD_WORK)/m4/.build_complete),)
m4:
	@echo "Using previously built m4."
else
m4: m4-setup
	cd $(BUILD_WORK)/m4 && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/m4
	+$(MAKE) -C $(BUILD_WORK)/m4 install \
		DESTDIR=$(BUILD_STAGE)/m4
	+$(MAKE) -C $(BUILD_WORK)/m4 install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/m4/.build_complete
endif
m4-package: m4-stage
	# m4.mk Package Structure
	rm -rf $(BUILD_DIST)/m4

	# m4.mk Prep m4
	cp -a $(BUILD_STAGE)/m4 $(BUILD_DIST)

	# m4.mk Sign
	$(call SIGN,m4,general.xml)

	# m4.mk Make .debs
	$(call PACK,m4,DEB_M4_V)

	# m4.mk Build cleanup
	rm -rf $(BUILD_DIST)/m4

.PHONY: m4 m4-package
