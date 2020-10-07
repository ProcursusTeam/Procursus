ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += bc
BC_VERSION := 1.07
DEB_BC_V   ?= $(BC_VERSION)

bc-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftp.gnu.org/gnu/bc/bc-$(BC_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,bc-$(BC_VERSION).tar.xz)
	$(call EXTRACT_TAR,bc-$(BC_VERSION).tar.gz,bc-$(BC_VERSION),bc)


	
ifneq ($(wildcard $(BUILD_WORK)/bc/.build_complete),)
bc:
	@echo "Using previously built bc."
else
bc: bc-setup
	cd $(BUILD_WORK)/bc && ./configure \
--build=aarch64-apple-darwin \
--host=aarch64-apple-darwin \
--disable-debug \
--disable-dependency-tracking \
--disable-silent-rules \
--with-libedit \
--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/bc install \
		DESTDIR="$(BUILD_STAGE)/bc"
	+$(MAKE) -C $(BUILD_WORK)/bc install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/bc.build_complete
endif

bc-package: bc-stage
	# bc.mk Package Structure
	rm -rf $(BUILD_DIST)/bc
	mkdir -p $(BUILD_DIST)/bc
	
	# bc.mk Prep bc
	cp -a $(BUILD_STAGE)/bc/usr $(BUILD_DIST)/bc
	
	# bc.mk Sign
	$(call SIGN,bc,general.xml)
	
	# bc.mk Make .debs
	$(call PACK,bc,DEB_BC_V)
	
	# bc.mk Build cleanup
	rm -rf $(BUILD_DIST)/bc

	.PHONY: bc bc-package

