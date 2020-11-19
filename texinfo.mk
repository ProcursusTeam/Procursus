ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += texinfo
TEXINFO_VERSION := 6.7
DEB_TEXINFO_V   ?= $(TEXINFO_VERSION)

texinfo-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/texinfo/texinfo-$(TEXINFO_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,texinfo-$(TEXINFO_VERSION).tar.xz)
	$(call EXTRACT_TAR,texinfo-$(TEXINFO_VERSION).tar.xz,texinfo-$(TEXINFO_VERSION),texinfo)

ifneq ($(wildcard $(BUILD_WORK)/texinfo/.build_complete),)
texinfo:
	@echo "Using previously built texinfo."
else
texinfo: texinfo-setup
	cd $(BUILD_WORK)/texinfo && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		--disable-debug \
		--disable-dependency-tracking
	+$(MAKE) -C $(BUILD_WORK)/texinfo
	+$(MAKE) -C $(BUILD_WORK)/texinfo install \
		DESTDIR=$(BUILD_STAGE)/texinfo
	touch $(BUILD_WORK)/texinfo/.build_complete
endif

texinfo-package: texinfo-stage
	# texinfo.mk Package Structure
	rm -rf $(BUILD_DIST)/texinfo
	mkdir -p $(BUILD_DIST)/texinfo
	
	# texinfo.mk Prep texinfo
	cp -a $(BUILD_STAGE)/texinfo $(BUI
	
	# texinfo.mk Sign
	$(call SIGN,texinfo,general.xml)
	
	# texinfo.mk Make .debs
	$(call PACK,texinfo,DEB_TEXINFO_V)
	
	# texinfo.mk Build cleanup
	rm -rf $(BUILD_DIST)/texinfo

.PHONY: texinfo texinfo-package
