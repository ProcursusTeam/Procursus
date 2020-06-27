ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += lzfse
LZFSE_VERSION := 1.0
DEB_LZFSE_V   ?= $(LZFSE_VERSION)

lzfse-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/lzfse/lzfse/archive/lzfse-$(LZFSE_VERSION).tar.gz
	$(call EXTRACT_TAR,lzfse-$(LZFSE_VERSION).tar.gz,lzfse-lzfse-$(LZFSE_VERSION),lzfse)

ifneq ($(wildcard $(BUILD_WORK)/lzfse/.build_complete),)
lzfse:
	@echo "Using previously built lzfse."
else
lzfse: lzfse-setup
	cd $(BUILD_WORK)/lzfse && cmake . \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=/ \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib \
		-DCMAKE_INSTALL_RPATH=/usr \
		-DCMAKE_OSX_SYSROOT="$(SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_CXX_FLAGS="$(CXXFLAGS)" \
		-DCOMMON_ARCH=$(DEB_ARCH) \
		-DCMAKE_FIND_ROOT_PATH=$(BUILD_BASE) 
	+$(MAKE) -C $(BUILD_WORK)/lzfse
	+$(MAKE) -C $(BUILD_WORK)/lzfse install \
		DESTDIR="$(BUILD_STAGE)/lzfse"
	touch $(BUILD_WORK)/lzfse/.build_complete
endif

lzfse-package: lzfse-stage
	# lzfse.mk Package Structure
	rm -rf $(BUILD_DIST)/lzfse
	mkdir -p $(BUILD_DIST)/lzfse
	
	# lzfse.mk Prep lzfse
	cp -a $(BUILD_STAGE)/lzfse/usr $(BUILD_DIST)/lzfse
	
	# lzfse.mk Sign
	$(call SIGN,lzfse,general.xml)
	
	# lzfse.mk Make .debs
	$(call PACK,lzfse,DEB_LZFSE_V)
	
	# lzfse.mk Build cleanup
	rm -rf $(BUILD_DIST)/lzfse

.PHONY: lzfse lzfse-package
