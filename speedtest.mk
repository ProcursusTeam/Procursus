ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += speedtest
SPEEDTEST_VERSION := 2.1.2
DEB_SPEEDTEST_V   ?= $(SPEEDTEST_VERSION)

speedtest-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/speedtest-$(SPEEDTEST_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/speedtest-$(SPEEDTEST_VERSION).tar.gz \
			https://github.com/sivel/speedtest-cli/archive/v$(SPEEDTEST_VERSION).tar.gz
	$(call EXTRACT_TAR,speedtest-$(SPEEDTEST_VERSION).tar.gz,speedtest-$(SPEEDTEST_VERSION),speedtest)

ifneq ($(wildcard $(BUILD_WORK)/speedtest/.build_complete),)
speedtest:
	@echo "Using previously built speedtest."
else
speedtest: speedtest-setup 
	mkdir -p $(BUILD_STAGE)/speedtest/usr/bin
	cp $(BUILD_WORK)/speedtest/speedtest.py $(BUILD_STAGE)/speedtest/usr/bin/speedtest
	touch $(BUILD_WORK)/speedtest/.build_complete
endif

speedtest-package: speedtest-stage
	# speedtest.mk Package Structure
	rm -rf $(BUILD_DIST)/speedtest
	mkdir -p $(BUILD_DIST)/speedtest
	
	# speedtest.mk Prep speedtest
	cp -a $(BUILD_STAGE)/speedtest $(BUILD_DIST)

	# speedtest.mk Fix permissions
	
	# speedtest.mk Make .debs
	$(call PACK,speedtest,DEB_SPEEDTEST_V)
	
	# speedtest.mk Build cleanup
	rm -rf $(BUILD_DIST)/speedtest

.PHONY: speedtest speedtest-package
