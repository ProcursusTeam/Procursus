ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += nettle
DOWNLOAD       += https://ftpmirror.gnu.org/nettle/nettle-$(NETTLE_VERSION).tar.gz{,.sig}
NETTLE_VERSION := 3.5.1
DEB_NETTLE_V   ?= $(NETTLE_VERSION)

nettle-setup: setup
	$(call PGP_VERIFY,nettle-$(NETTLE_VERSION).tar.gz)
	$(call EXTRACT_TAR,nettle-$(NETTLE_VERSION).tar.gz,nettle-$(NETTLE_VERSION),nettle)

ifneq ($(wildcard $(BUILD_WORK)/nettle/.build_complete),)
nettle:
	@echo "Using previously built nettle."
else
nettle: nettle-setup libgmp10
	cd $(BUILD_WORK)/nettle && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-assembler
	+$(MAKE) -C $(BUILD_WORK)/nettle
	+$(MAKE) -C $(BUILD_WORK)/nettle install \
		DESTDIR=$(BUILD_STAGE)/nettle
	+$(MAKE) -C $(BUILD_WORK)/nettle install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/nettle/.build_complete
endif

nettle-package: nettle-stage
	# nettle.mk Package Structure
	rm -rf $(BUILD_DIST)/nettle
	mkdir -p $(BUILD_DIST)/nettle
	
	# nettle.mk Prep nettle
	cp -a $(BUILD_STAGE)/nettle/usr $(BUILD_DIST)/nettle
	
	# nettle.mk Sign
	$(call SIGN,nettle,general.xml)
	
	# nettle.mk Make .debs
	$(call PACK,nettle,DEB_NETTLE_V)
	
	# nettle.mk Build cleanup
	rm -rf $(BUILD_DIST)/nettle

.PHONY: nettle nettle-package
