ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += pup
PUP_VERSION := 0.4.0
DEB_PUP_V   ?= $(PUP_VERSION)

pup-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/pup-$(PUP_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/pup-$(PUP_VERSION).tar.gz \
			https://github.com/ericchiang/pup/archive/v$(PUP_VERSION).tar.gz
	$(call EXTRACT_TAR,pup-$(PUP_VERSION).tar.gz,pup-$(PUP_VERSION),pup)
	mkdir -p $(BUILD_STAGE)/pup/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(MEMO_ARCH),arm64)
pup:
	@echo "Unsupported target $(MEMO_TARGET)"
else ifneq ($(wildcard $(BUILD_WORK)/pup/.build_complete),)
pup:
	@echo "Using previously built pup."
else
pup: pup-setup
	cd $(BUILD_WORK)/pup && go get -d -v .
	cd $(BUILD_WORK)/pup && \
		GOARCH=arm64 \
		GOOS=darwin \
		CGO_CFLAGS="$(CFLAGS)" \
		CGO_CPPFLAGS="$(CPPFLAGS)" \
		CGO_LDFLAGS="$(LDFLAGS)" \
		CGO_ENABLED=1 \
		CC="$(CC)" \
		go build
	cp -a $(BUILD_WORK)/pup/pup $(BUILD_STAGE)/pup/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	touch $(BUILD_WORK)/pup/.build_complete
endif

pup-package: pup-stage
	# pup.mk Package Structure
	rm -rf $(BUILD_DIST)/pup
	
	# pup.mk Prep pup
	cp -a $(BUILD_STAGE)/pup $(BUILD_DIST)/
	
	# pup.mk Sign
	$(call SIGN,pup,general.xml)
	
	# pup.mk Make .debs
	$(call PACK,pup,DEB_PUP_V)
	
	# pup.mk Build cleanup
	rm -rf $(BUILD_DIST)/pup

.PHONY: pup pup-package
