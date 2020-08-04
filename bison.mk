ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += bison
BISON_VERSION := 3.7.1
DEB_BISON_V   ?= $(BISON_VERSION)

bison-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/bison/bison-$(BISON_VERSION).tar.xz{,.sig}
	$(call PGP_VERIFY,bison-$(BISON_VERSION).tar.xz)
	$(call EXTRACT_TAR,bison-$(BISON_VERSION).tar.xz,bison-$(BISON_VERSION),bison)

ifneq ($(wildcard $(BUILD_WORK)/bison/.build_complete),)
bison:
	@echo "Using previously built bison."
else
bison: bison-setup m4
	cd $(BUILD_WORK)/bison && ./configure -C \
		--host=$(GNU_HOST_TRIPLE) \
		--prefix=/usr
	+$(MAKE) -C $(BUILD_WORK)/bison
	+$(MAKE) -C $(BUILD_WORK)/bison install \
		DESTDIR=$(BUILD_STAGE)/bison
	+$(MAKE) -C $(BUILD_WORK)/bison install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/bison/.build_complete
endif

bison-package: bison-stage
	# m4.mk Package Structure
	rm -rf $(BUILD_DIST)/bison
	mkdir -p $(BUILD_DIST)/bison
	
	# m4.mk Prep m4
	cp -a $(BUILD_STAGE)/bison/usr $(BUILD_DIST)/bison
	
	# bison.mk Sign
	$(call SIGN,bison,general.xml)
	
	# bison.mk Make .debs
	$(call PACK,bison,DEB_BISON_V)
	
	# bison.mk Build cleanup
	rm -rf $(BUILD_DIST)/bison

.PHONY: bison bison-package
