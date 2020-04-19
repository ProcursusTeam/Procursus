ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += npth
DOWNLOAD      += https://gnupg.org/ftp/gcrypt/npth/npth-$(NPTH_VERSION).tar.bz2{,.sig}
NPTH_VERSION  := 1.6
DEB_NPTH_V    ?= $(NPTH_VERSION)

npth-setup: setup
	$(call PGP_VERIFY,npth-$(NPTH_VERSION).tar.bz2)
	$(call EXTRACT_TAR,npth-$(NPTH_VERSION).tar.bz2,npth-$(NPTH_VERSION),npth)

ifneq ($(wildcard $(BUILD_WORK)/npth/.build_complete),)
npth:
	@echo "Using previously built npth."
else
npth: npth-setup
	cd $(BUILD_WORK)/npth && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/npth
	+$(MAKE) -C $(BUILD_WORK)/npth install \
		DESTDIR=$(BUILD_STAGE)/npth
	+$(MAKE) -C $(BUILD_WORK)/npth install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/npth/.build_complete
endif

npth-package: npth-stage
	# npth.mk Package Structure
	rm -rf $(BUILD_DIST)/npth
	mkdir -p $(BUILD_DIST)/npth
	
	# npth.mk Prep npth
	cp -a $(BUILD_STAGE)/npth/usr $(BUILD_DIST)/npth
	
	# npth.mk Sign
	$(call SIGN,npth,general.xml)
	
	# npth.mk Make .debs
	$(call PACK,npth,DEB_NPTH_V)
	
	# npth.mk Build cleanup
	rm -rf $(BUILD_DIST)/npth

.PHONY: npth npth-package
