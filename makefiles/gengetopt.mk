ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += gengetopt
GENGETOPT_VERSION := 2.23
DEB_GENGETOPT_V   ?= $(GENGETOPT_VERSION)

gengetopt-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://ftp.gnu.org/gnu/gengetopt/gengetopt-$(GENGETOPT_VERSION).tar.xz
	$(call EXTRACT_TAR,gengetopt-$(GENGETOPT_VERSION).tar.xz,gengetopt-$(GENGETOPT_VERSION),gengetopt)


ifneq ($(wildcard $(BUILD_WORK)/gengetopt/.build_complete),)
gengetopt:
	@echo "Using previously built gengetopt."
else
gengetopt: gengetopt-setup
	cd $(BUILD_WORK)/gengetopt && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/gengetopt
	+$(MAKE) -C $(BUILD_WORK)/gengetopt install \
		DESTDIR=$(BUILD_STAGE)/gengetopt
	touch $(BUILD_WORK)/gengetopt/.build_complete
endif

gengetopt-package: gengetopt-stage
	# gengetopt.mk Package Structure
	rm -rf $(BUILD_DIST)/gengetopt
	mkdir -p $(BUILD_DIST)/gengetopt
	
	# gengetopt.mk Prep gengetopt
	cp -a $(BUILD_STAGE)/gengetopt $(BUILD_DIST)
	
	# gengetopt.mk Sign
	$(call SIGN,gengetopt,general.xml)
	
	# gengetopt.mk Make .debs
	$(call PACK,gengetopt,DEB_GENGETOPT_V)
	
	# gengetopt.mk Build cleanup
	rm -rf $(BUILD_DIST)/gengetopt

.PHONY: gengetopt gengetopt-package
