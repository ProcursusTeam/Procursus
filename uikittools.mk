ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

ifneq ($(wildcard uikittools/.build_complete),)
uikittools:
	@echo "Using previously built uikittools."
else
uikittools: setup
	cd uikittools && make \
		CC=$(CC) \
		STRIP=$(STRIP) \
		CFLAGS="$(CFLAGS)"
	$(FAKEROOT) mkdir -p $(BUILD_STAGE)/uikittools/usr/bin
	for bin in uikittools/*; do \
		if [ -f $$bin ] && [ -x $$bin ]; then \
			$(FAKEROOT) cp $$bin $(BUILD_STAGE)/uikittools/usr/bin ; \
		fi \
	done
	touch uikittools/.build_complete
endif

.PHONY: uikittools
