ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS      += uikittools
UIKITTOOLS_VERSION := 2.0.3
DEB_UIKITTOOLS_V   ?= $(UIKITTOOLS_VERSION)

uikittools-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/uikittools-ng-$(UIKITTOOLS_VERSION).tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/uikittools-ng-$(UIKITTOOLS_VERSION).tar.gz \
			https://github.com/Diatrus/uikittools-ng/archive/v$(UIKITTOOLS_VERSION).tar.gz
	$(call EXTRACT_TAR,uikittools-ng-$(UIKITTOOLS_VERSION).tar.gz,uikittools-ng-$(UIKITTOOLS_VERSION),uikittools)

ifneq ($(wildcard $(BUILD_WORK)/uikittools/.build_complete),)
uikittools:
	@echo "Using previously built uikittools."
else
uikittools: uikittools-setup
	+$(MAKE) -C $(BUILD_WORK)/uikittools \
		CC=$(CC) \
		STRIP=$(STRIP) \
		CFLAGS="$(CFLAGS)"
	mkdir -p $(BUILD_STAGE)/uikittools/usr/bin
	for bin in $(BUILD_WORK)/uikittools/*; do \
		if [ -f $$bin ] && [ -x $$bin ]; then \
			cp $$bin $(BUILD_STAGE)/uikittools/usr/bin ; \
		fi \
	done
	touch $(BUILD_WORK)/uikittools/.build_complete
endif

uikittools-package: uikittools-stage
	# uikittools.mk Package Structure
	rm -rf $(BUILD_DIST)/uikittools
	mkdir -p $(BUILD_DIST)/uikittools
	
	# uikittools.mk Prep uikittools
	cp -a $(BUILD_STAGE)/uikittools/usr $(BUILD_DIST)/uikittools
	
	# uikittools.mk Make .debs
	$(call PACK,uikittools,DEB_UIKITTOOLS_V)
	
	# uikittools.mk Build cleanup
	rm -rf $(BUILD_DIST)/uikittools

.PHONY: uikittools uikittools-package
