ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

SED_VERSION := 4.7
DEB_SED_V   ?= $(SED_VERSION)

# `gl_cv_func_ftello_works=yes` workaround for gnulib issue on macOS Catalina, presumably also
# iOS 13, borrowed from Homebrew formula for coreutils
# TODO: Remove when GNU fixes this issue

ifneq ($(wildcard $(BUILD_WORK)/sed/.build_complete),)
sed:
	@echo "Using previously built sed."
else
sed: setup
	cd $(BUILD_WORK)/sed && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr \
		--disable-dependency-tracking \
		gl_cv_func_ftello_works=yes
	+$(MAKE) -C $(BUILD_WORK)/sed
	+$(MAKE) -C $(BUILD_WORK)/sed install \
		DESTDIR=$(BUILD_STAGE)/sed
	touch $(BUILD_WORK)/sed/.build_complete
endif

sed-package: sed-stage
	# sed.mk Package Structure
	rm -rf $(BUILD_DIST)/sed
	mkdir -p $(BUILD_DIST)/sed
	
	# sed.mk Prep sed
	$(FAKEROOT) cp -a $(BUILD_STAGE)/sed/usr $(BUILD_DIST)/sed
	
	# sed.mk Sign
	$(call SIGN,sed,general.xml)
	
	# sed.mk Make .debs
	$(call PACK,sed,DEB_SED_V)
	
	# sed.mk Build cleanup
	rm -rf $(BUILD_DIST)/sed

.PHONY: sed sed-package
