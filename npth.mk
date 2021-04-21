ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS += npth
NPTH_VERSION  := 1.6
DEB_NPTH_V    ?= $(NPTH_VERSION)-2

npth-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://gnupg.org/ftp/gcrypt/npth/npth-$(NPTH_VERSION).tar.bz2{,.sig}
	$(call PGP_VERIFY,npth-$(NPTH_VERSION).tar.bz2)
	$(call EXTRACT_TAR,npth-$(NPTH_VERSION).tar.bz2,npth-$(NPTH_VERSION),npth)

ifneq ($(wildcard $(BUILD_WORK)/npth/.build_complete),)
npth:
	@echo "Using previously built npth."
else
npth: npth-setup
	cd $(BUILD_WORK)/npth && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/npth
	+$(MAKE) -C $(BUILD_WORK)/npth install \
		DESTDIR=$(BUILD_STAGE)/npth
	+$(MAKE) -C $(BUILD_WORK)/npth install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/npth/.build_complete
endif

npth-package: npth-stage
	# npth.mk Package Structure
	rm -rf $(BUILD_DIST)/libnpth0{,-dev}
	mkdir -p $(BUILD_DIST)/libnpth0{,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# npth.mk Prep libnpth0
	cp -a $(BUILD_STAGE)/npth/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libnpth.0.dylib $(BUILD_DIST)/libnpth0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# npth.mk Prep libnpth0-dev
	cp -a $(BUILD_STAGE)/npth/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libnpth.dylib $(BUILD_DIST)/libnpth0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/npth/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,include,share} $(BUILD_DIST)/libnpth0-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# npth.mk Sign
	$(call SIGN,libnpth0,general.xml)
	$(call SIGN,libnpth0-dev,general.xml)

	# npth.mk Make .debs
	$(call PACK,libnpth0,DEB_NPTH_V)
	$(call PACK,libnpth0-dev,DEB_NPTH_V)

	# npth.mk Build cleanup
	rm -rf $(BUILD_DIST)/libnpth0{,-dev}

.PHONY: npth npth-package
