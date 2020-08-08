ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += mpc
MPC_VERSION := 1.1.0
DEB_MPC_V   ?= $(MPC_VERSION)

mpc-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftp.gnu.org/gnu/mpc/mpc-$(MPC_VERSION).tar.gz
	$(call EXTRACT_TAR,mpc-$(MPC_VERSION).tar.gz,mpc-$(MPC_VERSION),mpc)

ifneq ($(wildcard $(BUILD_WORK)/mpc/.build_complete),)
mpc:
	@echo "Using previously built mpc."
else
mpc: libgmp10 mpfr
	cd $(BUILD_WORK)/mpc && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/mpc
	+$(MAKE) -C $(BUILD_WORK)/mpc install \
		DESTDIR=$(BUILD_STAGE)/mpc
	touch $(BUILD_WORK)/mpc/.build_complete
endif

mpc-package: mpc-stage
	# mpc.mk Package Structure
	rm -rf $(BUILD_DIST)/mpc
	mkdir -p $(BUILD_DIST)/mpc
	
	# mpc.mk Prep mpc
	cp -a $(BUILD_STAGE)/mpc/usr $(BUILD_DIST)/mpc
	
	# mpc.mk Sign
	$(call SIGN,mpc,general.xml)
	
	# mpc.mk Make .debs
	$(call PACK,mpc,DEB_MPC_V)
	
	# mpc.mk Build cleanup
	rm -rf $(BUILD_DIST)/mpc

.PHONY: mpc mpc-package
