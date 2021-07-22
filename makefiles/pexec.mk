ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += pexec
PEXEC_VERSION := 1.0rc8
DEB_PEXEC_V   ?= $(shell $(SED) 's/rc/~rc/g' <<< $(PEXEC_VERSION))

pexec-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) http://ftp.gnu.org/gnu/pexec/pexec-$(PEXEC_VERSION).tar.gz
	$(call EXTRACT_TAR,pexec-$(PEXEC_VERSION).tar.gz,pexec-$(PEXEC_VERSION),pexec)
	$(call DO_PATCH,pexec,pexec,-p1)

ifneq ($(wildcard $(BUILD_WORK)/pexec/.build_complete),)
pexec:
	@echo "Using previously built pexec."
else
pexec: pexec-setup
	cd $(BUILD_WORK)/pexec && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/pexec
	+$(MAKE) -C $(BUILD_WORK)/pexec install \
		DESTDIR=$(BUILD_STAGE)/pexec
	touch $(BUILD_WORK)/pexec/.build_complete
endif

pexec-package: pexec-stage
	# pexec.mk Package Structure
	rm -rf $(BUILD_DIST)/pexec
	
	# pexec.mk Prep pexec
	cp -a $(BUILD_STAGE)/pexec $(BUILD_DIST)
	
	# pexec.mk Sign
	$(call SIGN,pexec,general.xml)
	
	# pexec.mk Make .debs
	$(call PACK,pexec,DEB_PEXEC_V)
	
	# pexec.mk Build cleanup
	rm -rf $(BUILD_DIST)/pexec

.PHONY: pexec pexec-package
