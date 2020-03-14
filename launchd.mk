ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

# TODO: we shouldn’t need to patch the config output to make dpkg use the right architecture params

ifneq ($(wildcard $(BUILD_WORK)/launchd/.build_complete),)
launchd:
	@echo "Using previously built launchd."
else
launchd: setup readline
	$(SED) -i '/#include <sys\/socket.h>/a #include <sys\/sockio.h>' $(BUILD_WORK)/launchd/support/launchctl.c
	cd $(BUILD_WORK)/launchd/support && $(CC) \
		-DPRIVATE launchctl.c \
		-o ../launchctl \
		-w $(CFLAGS) \
		-I$(BUILD_WORK)/launchd/src \
		-I$(BUILD_WORK)/launchd/liblaunch \
		-framework CoreFoundation \
		-framework IOKit \
		-lreadline
	mkdir -p $(BUILD_STAGE)/launchd/usr/bin
	cp -a $(BUILD_WORK)/launchd/launchctl $(BUILD_STAGE)/launchd/usr/bin
	touch $(BUILD_WORK)/launchd/.build_complete
endif

.PHONY: launchd
