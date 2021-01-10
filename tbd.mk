ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += tbd
TBD_VERSION := 2.2
DEB_TBD_V   ?= $(TBD_VERSION)

tbd-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/tbd-$(TBD_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/tbd-$(TBD_VERSION).tar.gz \
			https://github.com/inoahdev/tbd/archive/$(TBD_VERSION).tar.gz
	$(call EXTRACT_TAR,tbd-$(TBD_VERSION).tar.gz,tbd-$(TBD_VERSION),tbd)
	$(SED) -i -e 's/^CFLAGS=/CFLAGS+=/1m' \
		-e 's/\t@/\t/g' \
		-e 22's/$$/ $$(CFLAGS) &/' \
		$(BUILD_WORK)/tbd/Makefile

ifneq ($(wildcard $(BUILD_WORK)/tbd/.build_complete),)
tbd:
	@echo "Using previously built tbd."
else
tbd: tbd-setup ncurses gettext file
	+$(MAKE) -C $(BUILD_WORK)/tbd \
		CC="$(CC)"
	$(GINSTALL) -Dm755 $(BUILD_WORK)/tbd/bin/tbd $(BUILD_STAGE)/tbd/usr/bin/tbd
	touch $(BUILD_WORK)/tbd/.build_complete
endif

tbd-package: tbd-stage
	# tbd.mk Package Structure
	rm -rf $(BUILD_DIST)/tbd
	
	# tbd.mk Prep tbd
	cp -a $(BUILD_STAGE)/tbd $(BUILD_DIST)
	
	# tbd.mk Sign
	$(call SIGN,tbd,general.xml)
	
	# tbd.mk Make .debs
	$(call PACK,tbd,DEB_TBD_V)
	
	# tbd.mk Build cleanup
	rm -rf $(BUILD_DIST)/tbd

.PHONY: tbd tbd-package
