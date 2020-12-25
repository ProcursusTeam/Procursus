ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += pbupload
PBUPLOAD_VERSION      := 1.0.0
DEB_PBUPLOAD_V        ?= $(PBUPLOAD_VERSION)
PBUPLOAD_LIBS         := -framework Foundation -framework UIKit

pbupload-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/pbupload-$(PBUPLOAD_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/pbupload-$(PBUPLOAD_VERSION).tar.gz \
			https://github.com/quiprr/pbupload/archive/v$(PBUPLOAD_VERSION).tar.gz
	$(call EXTRACT_TAR,pbupload-$(PBUPLOAD_VERSION).tar.gz,pbupload-$(PBUPLOAD_VERSION),pbupload)
	mkdir -p $(BUILD_STAGE)/pbupload/usr/bin

ifneq ($(wildcard $(BUILD_WORK)/pbupload/.build_complete),)
pbupload:
	@echo "Using previously built pbupload."
else
pbupload: pbupload-setup 
	$(CC) $(CFLAGS) -fobjc-arc \
		$(BUILD_WORK)/pbupload/Sources/pbupload.m \
		-o $(BUILD_STAGE)/pbupload/usr/bin/pbupload \
		$(LDFLAGS) \
		$(PBUPLOAD_LIBS)
	touch $(BUILD_WORK)/pbupload/.build_complete
endif

pbupload-package: pbupload-stage
	# pbupload.mk Package Structure
	rm -rf $(BUILD_DIST)/pbupload
	mkdir -p $(BUILD_DIST)/pbupload/usr/bin

	# pbupload.mk Prep pbupload
	cp -a $(BUILD_STAGE)/pbupload/usr/bin/pbupload $(BUILD_DIST)/pbupload/usr/bin

	# pbupload.mk Sign
	$(call SIGN,pbupload,general.xml)

	# pbupload.mk Make .debs
	$(call PACK,pbupload,DEB_PBUPLOAD_V)

	# pbupload.mk Build cleanup
	rm -rf $(BUILD_DIST)/pbupload

.PHONY: pbupload pbupload-package
