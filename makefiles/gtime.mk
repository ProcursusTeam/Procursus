ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += gtime
GTIME_VERSION := 1.9
DEB_GTIME_V   ?= $(GTIME_VERSION)

gtime-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftp.gnu.org/gnu/time/time-1.9.tar.gz{,.sig}
	$(call PGP_VERIFY,time-$(GTIME_VERSION).tar.gz)
	$(call EXTRACT_TAR,time-$(GTIME_VERSION).tar.gz,time-$(GTIME_VERSION),gtime)

ifneq ($(wildcard $(BUILD_WORK)/gtime/.build_complete),)
gtime:
	@echo "Using previously built gtime."
else
gtime: gtime-setup
	cd $(BUILD_WORK)/gtime && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--program-prefix=g \
		--with-packager=Procursus
		--with-packager-bug-reports=https://github.com/ProcursusTeam/Procursus/issues
	+$(MAKE) -C $(BUILD_WORK)/gtime
	+$(MAKE) -C $(BUILD_WORK)/gtime install \
		DESTDIR=$(BUILD_STAGE)/gtime
	touch $(BUILD_WORK)/gtime/.build_complete
endif

gtime-package: gtime-stage
	# gtime.mk Package Structure
	rm -rf $(BUILD_DIST)/gtime
	
	# gtime.mk Prep gtime
	cp -a $(BUILD_STAGE)/gtime $(BUILD_DIST)
	
	# gtime.mk Sign
	$(call SIGN,gtime,general.xml)
	
	# gtime.mk Make .debs
	$(call PACK,gtime,DEB_GTIME_V)
	
	# gtime.mk Build cleanup
	rm -rf $(BUILD_DIST)/gtime

.PHONY: gtime gtime-package
