ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += libmpc
LIBMPC_VERSION := 1.1.0
DEB_LIBMPC_V   ?= $(LIBMPC_VERSION)

libmpc-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftp.gnu.org/gnu/mpc/mpc-$(LIBMPC_VERSION).tar.gz
	$(call EXTRACT_TAR,mpc-$(LIBMPC_VERSION).tar.gz,mpc-$(LIBMPC_VERSION),libmpc)

ifneq ($(wildcard $(BUILD_WORK)/libmpc/.build_complete),)
libmpc:
	@echo "Using previously built libmpc."
else
libmpc: libmpc-setup libgmp10 libmpfr
	cd $(BUILD_WORK)/libmpc && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/libmpc
	+$(MAKE) -C $(BUILD_WORK)/libmpc install \
		DESTDIR=$(BUILD_STAGE)/libmpc
	+$(MAKE) -C $(BUILD_WORK)/libmpc install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/libmpc/.build_complete
endif

libmpc-package: libmpc-stage
	# libmpc.mk Package Structure
	rm -rf $(BUILD_DIST)/{libmpc3,libmpc-dev}
	mkdir -p \
		$(BUILD_DIST)/libmpc3/usr/lib
		$(BUILD_DIST)/libmpc-dev/usr/{lib,include}
	
	# libmpc.mk Prep mpc
	cp -a $(BUILD_STAGE)/libmpc/usr/lib/libmpc*dylib $(BUILD_DIST)/libmpc3/usr/lib
	cp -a $(BUILD_STAGE)/libmpc/usr/include $(BUILD_DIST)/libmpc-dev/usr
	cp -a $(BUILD_STAGE)/libmpc/usr/lib/libmpc.a $(BUILD_DIST)/libmpc-dev/usr/lib
	
	# libmpc.mk Sign
	$(call SIGN,libmpc3,general.xml)
	$(call SIGN,libmpc-dev,general.xml)
	
	# libmpc.mk Make .debs
	$(call PACK,libmpc3,DEB_LIBMPC_V)
	$(call PACK,libmpc-dev,DEB_LIBMPC_V)
	
	# libmpc.mk Build cleanup
	rm -rf $(BUILD_DIST)/{libmpc3,libmpc-dev}

.PHONY: libmpc libmpc-package
