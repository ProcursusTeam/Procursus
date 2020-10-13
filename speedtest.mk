ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

STRAPPROJECTS      += speedtest
SPEEDTEST_VERSION  := 2.1.2
DEB_SPEEDTEST_V    ?= $(SPEEDTEST_VERSION)

speedtest-setup: setup
	wget -O speedtest -P $(BUILD_SOURCE) https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py

ifneq ($(wildcard $(BUILD_WORK)/speedtest/.build_complete),)
speedtest:
	@echo "Using previously built speedtest."
else
speedtest: speedtest-setup pcre
	touch $(BUILD_WORK)/speedtest/.build_complete
endif

speedtest-package: speedtest-stage
	rm -rf $(BUILD_DIST)/speedtest
	mkdir -p $(BUILD_DIST)/speedtest
	
	cp -a $(BUILD_STAGE)/speedtest/usr $(BUILD_DIST)/speedtest
	
	$(call SIGN,speedtest,general.xml)
	
	$(call PACK,speedtest,DEB_SPEEDTEST_V)
	
	rm -rf $(BUILD_DIST)/speedtest

.PHONY: speedtest speedtest-package