ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

UIKITTOOLS_VERSION := 2.0.2
DEB_UIKITTOOLS_V   ?= $(UIKITTOOLS_VERSION)

ifneq ($(wildcard uikittools/.build_complete),)
uikittools:
	@echo "Using previously built uikittools."
else
uikittools: setup
	cd uikittools && make \
		CC=$(CC) \
		STRIP=$(STRIP) \
		CFLAGS="$(CFLAGS)"
	mkdir -p $(BUILD_STAGE)/uikittools/usr/bin
	for bin in uikittools/*; do \
		if [ -f $$bin ] && [ -x $$bin ]; then \
			cp $$bin $(BUILD_STAGE)/uikittools/usr/bin ; \
		fi \
	done
	touch uikittools/.build_complete
endif

uikittools-package: uikittools-stage
	# uikittools.mk Package Structure
	rm -rf $(BUILD_DIST)/uikittools
	mkdir -p $(BUILD_DIST)/uikittools
	
	# uikittools.mk Prep uikittools
	$(FAKEROOT) cp -a $(BUILD_STAGE)/uikittools/usr $(BUILD_DIST)/uikittools
	
	# uikittools.mk Make .debs
	$(call PACK,uikittools,DEB_UIKITTOOLS_V)
	
	# uikittools.mk Build cleanup
	rm -rf $(BUILD_DIST)/uikittools

.PHONY: uikittools uikittools-package
