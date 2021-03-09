ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += guile
GUILE_VERSION := 3.0.5
DEB_GUILE_V   ?= $(GUILE_VERSION)

guile-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://mirror.its.dal.ca/gnu/guile/guile-$(GUILE_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,guile-$(GUILE_VERSION).tar.gz)
	$(call EXTRACT_TAR,guile-$(GUILE_VERSION).tar.gz,guile-$(GUILE_VERSION),guile)

ifneq ($(wildcard $(BUILD_WORK)/guile/.build_complete),)
guile:
	@echo "Using previously built guile."
else
guile: guile-setup libgmp10 libiconv libunistring libgc libffi readline gettext libtool
	cd $(BUILD_WORK)/guile && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)
	+$(MAKE) -C $(BUILD_WORK)/guile
	+$(MAKE) -C $(BUILD_WORK)/guile install \
		DESTDIR=$(BUILD_STAGE)/guile
	+$(MAKE) -C $(BUILD_WORK)/guile install \
		DESTDIR=$(BUILD_BASE)
	touch $(BUILD_WORK)/guile/.build_complete
endif

guile-package: guile-stage
	# guile.mk Package Structure
	rm -rf $(BUILD_DIST)/guile-3.0
	mkdir -p $(BUILD_DIST)/guile-3.0
	
	# guile.mk Prep guile
	cp -a $(BUILD_STAGE)/guile/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX) $(BUILD_DIST)/guile-3.0
	
	# guile.mk Sign
	$(call SIGN,guile3.0,general.xml)
	
	# guile.mk Make .debs
	$(call PACK,guile-3.0,DEB_GUILE_V)
	
	# guile.mk Build cleanup
	rm -rf $(BUILD_DIST)/guile

.PHONY: guile guile-package
