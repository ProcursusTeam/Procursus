ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS      += haydenfetch
HAYDENFETCH_VERSION := 1.0.0
DEB_HAYDENFETCH_V   ?= $(HAYDENFETCH_VERSION)

haydenfetch-setup: setup
	if [ ! -d "$(BUILD_WORK)/haydenfetch" ]; then \
	git clone https://github.com/asdfugil/haydenfetch.git  $(BUILD_WORK)/haydenfetch; \
	git fetch origin; \
	git reset --hard origin/master; \
	git checkout "3d16901a8d0e8699b7d1484f135d7c2aad402ade"; \
	fi

ifneq ($(wildcard $(BUILD_WORK)/haydenfetch/.build_complete),)
haydenfetch:
	@echo "Using previously built haydenfetch."
else
haydenfetch: haydenfetch-setup
	+$(MAKE) -C $(BUILD_WORK)/haydenfetch install \
		PREFIX=/usr \
		DESTDIR=$(BUILD_STAGE)/haydenfetch
	touch $(BUILD_WORK)/haydenfetch/.build_complete
endif

haydenfetch-package: haydenfetch-stage
	# haydenfetch.mk Package Structure
	rm -rf $(BUILD_DIST)/haydenfetch
	
	# haydenfetch.mk Prep haydenfetch
	cp -a $(BUILD_STAGE)/haydenfetch $(BUILD_DIST)
	
	# haydenfetch.mk Make .debs
	$(call PACK,haydenfetch,DEB_HAYDENFETCH_V)
	
	# haydenfetch.mk Build cleanup
	rm -rf $(BUILD_DIST)/haydenfetch

.PHONY: haydenfetch haydenfetch-package
