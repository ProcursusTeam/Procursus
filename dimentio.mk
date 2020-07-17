ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS        += dimentio
DIMENTIO_VERSION   := 1.0
DEB_DIMENTIO_V     ?= $(DIMENTIO_VERSION)

dimentio-setup: setup
	-[ ! -e "$(BUILD_SOURCE)/dimentio-$(DIMENTIO_VERSION).tar.gz" ] \
		&& wget -nc -O$(BUILD_SOURCE)/dimentio-$(DIMENTIO_VERSION).tar.gz \
			https://github.com/ProcursusTeam/dimentio/archive/$(DIMENTIO_VERSION).tar.gz
	$(call EXTRACT_TAR,dimentio-$(DIMENTIO_VERSION).tar.gz,dimentio-$(DIMENTIO_VERSION),dimentio)

ifneq ($(wildcard $(BUILD_WORK)/dimentio/.build_complete),)
dimentio:
	@echo "Using previously built dimentio."
else
dimentio: dimentio-setup
	cd $(BUILD_WORK)/dimentio
	mkdir -p $(BUILD_STAGE)/dimentio/usr/bin
	$(CC) $(CFLAGS) \
		-framework CoreFoundation \
		-framework IOKit \
		-lcompression \
		$(BUILD_WORK)/dimentio/dimentio.c \
		-o $(BUILD_STAGE)/dimentio/usr/bin/dimentio
	touch $(BUILD_WORK)/dimentio/.build_complete
endif

dimentio-package: dimentio-stage
	# dimentio.mk Package Structure
	rm -rf $(BUILD_DIST)/dimentio
	mkdir -p $(BUILD_DIST)/dimentio
	
	# dimentio.mk Prep dimentio
	cp -a $(BUILD_STAGE)/dimentio/usr $(BUILD_DIST)/dimentio
	
	# dimentio.mk Sign
	$(call SIGN,dimentio,tfp0.xml)
	
	# dimentio.mk Make .debs
	$(call PACK,dimentio,DEB_DIMENTIO_V)
	
	# dimentio.mk Build cleanup
	rm -rf $(BUILD_DIST)/dimentio

.PHONY: dimentio dimentio-package
