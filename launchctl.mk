ifneq ($(CHECKRA1N_MEMO),1)
$(error Use the main Makefile)
endif

LAUNCHCTL_VERSION := 23-2
DEB_LAUNCHCTL_V   ?= $(LAUNCHCTL_VERSION)

launchctl:
	@echo "Launchctl package won't build because you need to put the launchctl binary in $(BUILD_INFO)."

launchctl-package: launchctl-stage
	# launchctl.mk Package Structure
	rm -rf $(BUILD_DIST)/launchctl
	mkdir -p $(BUILD_DIST)/launchctl/{usr/bin,bin}

	# launchctl.mk Prep launchctl
	$(FAKEROOT) cp -a $(BUILD_INFO)/launchctl $(BUILD_DIST)/launchctl/usr/bin
	ln -s /usr/bin/launchctl $(BUILD_DIST)/launchctl/bin/launchctl

	# launchctl.mk Sign launchctl
	$(call SIGN,launchctl,launchctl.xml)
	
	# launchctl.mk Make .debs
	$(call PACK,launchctl,DEB_LAUNCHCTL_V)
	
	# launchctl.mk Build cleanup
	rm -rf $(BUILD_DIST)/launchctl

.PHONY: launchctl launchctl-package
