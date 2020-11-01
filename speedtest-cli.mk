ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += speedtest-cli
SPEEDTEST-CLI_VERSION := 2.1.2
DEB_SPEEDTEST-CLI_V   ?= $(SPEEDTEST-CLI_VERSION)

speedtest-cli-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/speedtest-cli-$(SPEEDTEST-CLI_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/speedtest-cli-$(SPEEDTEST-CLI_VERSION).tar.gz \
			https://github.com/sivel/speedtest-cli/archive/v$(SPEEDTEST-CLI_VERSION).tar.gz
	$(call EXTRACT_TAR,speedtest-cli-$(SPEEDTEST-CLI_VERSION).tar.gz,speedtest-cli-$(SPEEDTEST-CLI_VERSION),speedtest-cli)

ifneq ($(wildcard $(BUILD_WORK)/speedtest-cli/.build_complete),)
speedtest-cli:
	@echo "Using previously built speedtest-cli."
else
speedtest-cli: speedtest-cli-setup 
	$(GINSTALL) -Dm 755 $(BUILD_WORK)/speedtest-cli/speedtest.py -t "$(BUILD_STAGE)/speedtest-cli/usr/bin"
	mv $(BUILD_STAGE)/speedtest-cli/usr/bin/speedtest.py $(BUILD_STAGE)/speedtest-cli/usr/bin/speedtest-cli
	ln -s speedtest-cli $(BUILD_STAGE)/speedtest-cli/usr/bin/speedtest
	$(GINSTALL) -Dm 644 $(BUILD_WORK)/speedtest-cli/speedtest-cli.1 -t "$(BUILD_STAGE)/speedtest-cli/usr/share/man/man1"
	touch $(BUILD_WORK)/speedtest-cli/.build_complete
endif

speedtest-cli-package: speedtest-cli-stage
	# speedtest-cli.mk Package Structure
	rm -rf $(BUILD_DIST)/speedtest-cli
	mkdir -p $(BUILD_DIST)/speedtest-cli
	
	# speedtest-cli.mk Prep speedtest-cli
	cp -a $(BUILD_STAGE)/speedtest-cli $(BUILD_DIST)

	# speedtest-cli.mk Make .debs
	$(call PACK,speedtest-cli,DEB_SPEEDTEST-CLI_V)
	
	# speedtest-cli.mk Build cleanup
	rm -rf $(BUILD_DIST)/speedtest-cli

.PHONY: speedtest-cli speedtest-cli-package
