ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += ghostbin
GHOSTBIN_COMMIT   := 0e0a3b72c3379e51bf03fe676af3a74a01239a47
GHOSTBIN_VERSION  := 1.0+git20201225.$(shell echo $(GHOSTBIN_COMMIT) | cut -c -7)
DEB_GHOSTBIN_V    ?= $(GHOSTBIN_VERSION)

ghostbin-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/ghostbin-v$(GHOSTBIN_COMMIT).tar.gz" ] \
		&& wget -q -nc -O$(BUILD_SOURCE)/ghostbin-v$(GHOSTBIN_COMMIT).tar.gz \
			https://github.com/DHowett/spectre/archive/$(GHOSTBIN_COMMIT).tar.gz
	$(call EXTRACT_TAR,ghostbin-v$(GHOSTBIN_COMMIT).tar.gz,spectre-$(GHOSTBIN_COMMIT),ghostbin)
	$(SED) -i '/account creation has been disabled/,+3d' $(BUILD_WORK)/ghostbin/auth.go

ifneq ($(ARCHES),arm64)
ghostbin:
	@echo "Unsupported target $(MEMO_TARGET)"
else ifneq ($(wildcard $(BUILD_WORK)/ghostbin/.build_complete),)
ghostbin:
	@echo "Using previously built ghostbin."
else
ghostbin: ghostbin-setup
	+cd $(BUILD_WORK)/ghostbin && \
		GOARCH=arm64 \
		GOOS=darwin \
		CGO_CFLAGS="$(CFLAGS)" \
		CGO_CPPFLAGS="$(CPPFLAGS)" \
		CGO_LDFLAGS="$(LDFLAGS)" \
		CGO_ENABLED=1 \
		CC="$(CC)" \
		go build
	mkdir -p $(BUILD_STAGE)/ghostbin/{Library/LaunchDaemons,usr/{libexec/ghostbin,bin}}
	cp -a $(BUILD_WORK)/ghostbin/{ghostbin,ghosts.yml,templates,languages.yml,public} $(BUILD_STAGE)/ghostbin/usr/libexec/ghostbin
	cp -a $(BUILD_INFO)/ghostbin-wrapper $(BUILD_STAGE)/ghostbin/usr/bin/ghostbin
	cp -a $(BUILD_INFO)/net.howett.ghostbin.plist $(BUILD_STAGE)/ghostbin/Library/LaunchDaemons
	touch $(BUILD_WORK)/ghostbin/.build_complete
endif

ghostbin-package: ghostbin-stage
	# ghostbin.mk Package Structure
	rm -rf $(BUILD_DIST)/ghostbin
	
	# ghostbin.mk Prep ghostbin
	cp -a $(BUILD_STAGE)/ghostbin $(BUILD_DIST)
	
	# ghostbin.mk Sign
	$(call SIGN,ghostbin,general.xml)
	
	# ghostbin.mk Make .debs
	$(call PACK,ghostbin,DEB_GHOSTBIN_V)
	
	# ghostbin.mk Build cleanup
	rm -rf $(BUILD_DIST)/ghostbin
	
.PHONY: ghostbin ghostbin-package
