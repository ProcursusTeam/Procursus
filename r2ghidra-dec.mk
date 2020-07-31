ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += r2ghidra-dec
R2GHIDRA_VERSION := 4.5.0
DEB_R2GHIDRA_V   ?= $(R2GHIDRA_VERSION)

r2ghidra-dec-setup: setup
	if [ ! -d "$(BUILD_WORK)/r2ghidra-dec" ]; then \
		git clone https://github.com/radareorg/r2ghidra-dec.git $(BUILD_WORK)/r2ghidra-dec; \
		cd "$(BUILD_WORK)/r2ghidra-dec"; \
		git fetch origin; \
		git reset --hard origin/master; \
		git checkout HEAD .; \
		git submodule update --init; \
	fi
	$(call DO_PATCH,r2ghidra,r2ghidra-dec,-p1)

ifneq ($(wildcard $(BUILD_WORK)/r2ghidra-dec/.build_complete),)
r2ghidra-dec:
	@echo "Using previously built r2ghidra-dec."
else
r2ghidra-dec: r2ghidra-dec-setup radare2
	mkdir -p $(BUILD_WORK)/../../native && cp -a $(BUILD_WORK)/r2ghidra-dec/ghidra $(BUILD_WORK)/../../native
	+cd $(BUILD_WORK)/../../native/ghidra && unset CFLAGS CXXFLAGS CPPFLAGS LDFLAGS && cmake .; \
	$(MAKE) -C $(BUILD_WORK)/../../native/ghidra sleighc
	cd $(BUILD_WORK)/r2ghidra-dec && cmake . \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_INSTALL_NAME_TOOL=$(I_N_T) \
		-DCMAKE_INSTALL_PREFIX=/ \
		-DCMAKE_INSTALL_NAME_DIR=/usr/lib \
		-DCMAKE_INSTALL_RPATH=/usr \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_C_FLAGS="$(CFLAGS)" \
		-DCMAKE_FIND_ROOT_PATH="$(BUILD_BASE)" \
		-DRadare2_INCLUDE_DIRS="$(BUILD_BASE)/usr/include/libr"
	+PATH="$(BUILD_WORK)/../../native/ghidra:$(PATH)" $(MAKE) -C $(BUILD_WORK)/r2ghidra-dec
	$(MAKE) -C $(BUILD_WORK)/r2ghidra-dec install \
		DESTDIR="$(BUILD_STAGE)/r2ghidra-dec"
	touch $(BUILD_WORK)/r2ghidra-dec/.build_complete
endif

r2ghidra-dec-package: r2ghidra-dec-stage
	# r2ghidra-dec.mk Package Structure
	rm -rf $(BUILD_DIST)/r2ghidra-dec
	mkdir -p $(BUILD_DIST)/r2ghidra-dec
	
	# r2ghidra-dec.mk Prep r2ghidra-dec
	cp -a $(BUILD_STAGE)/r2ghidra-dec/usr $(BUILD_DIST)/r2ghidra-dec
	
	# r2ghidra-dec.mk Sign
	$(call SIGN,r2ghidra-dec,general.xml)
	
	# r2ghidra-dec.mk Make .debs
	$(call PACK,r2ghidra-dec,DEB_R2GHIDRA_V)
	
	# r2ghidra-dec.mk Build cleanup
	rm -rf $(BUILD_DIST)/r2ghidra-dec

.PHONY: r2ghidra-dec r2ghidra-dec-package
