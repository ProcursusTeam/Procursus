ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += lolcat
LOLCAT_VERSION := 1.1
DEB_LOLCAT_V   ?= $(LOLCAT_VERSION)

lolcat-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/lolcat-$(LOLCAT_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/lolcat-$(LOLCAT_VERSION).tar.gz https://github.com/jaseg/lolcat/archive/v$(LOLCAT_VERSION).tar.gz
	$(call EXTRACT_TAR,lolcat-$(LOLCAT_VERSION).tar.gz,lolcat-$(LOLCAT_VERSION),lolcat)
	mkdir -p $(BUILD_STAGE)/lolcat/usr/games

ifneq ($(wildcard $(BUILD_WORK)/lolcat/.build_complete),)
lolcat:
	@echo "Using previously built lolcat."
else
lolcat: lolcat-setup 
	+$(MAKE) -C $(BUILD_WORK)/lolcat
	+$(MAKE) -C $(BUILD_WORK)/lolcat install \
		DESTDIR=$(BUILD_STAGE)/lolcat/usr/games
	touch $(BUILD_WORK)/lolcat/.build_complete
endif

lolcat-package: lolcat-stage
	# lolcat.mk Package Structure
	rm -rf $(BUILD_DIST)/lolcat
	mkdir -p $(BUILD_DIST)/lolcat
	
	# lolcat.mk Prep lolcat
	cp -a $(BUILD_STAGE)/lolcat/usr $(BUILD_DIST)/lolcat
	
	# lolcat.mk Sign
	$(call SIGN,lolcat,general.xml)
	
	# lolcat.mk Make .debs
	$(call PACK,lolcat,DEB_LOLCAT_V)
	
	# lolcat.mk Build cleanup
	rm -rf $(BUILD_DIST)/lolcat

.PHONY: lolcat lolcat-package
