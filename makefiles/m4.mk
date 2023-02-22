ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += m4
M4_VERSION  := 1.4.19
DEB_M4_V    ?= $(M4_VERSION)-1

m4-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://ftpmirror.gnu.org/m4/m4-$(M4_VERSION).tar.gz{$(comma).sig})
	$(call PGP_VERIFY,m4-$(M4_VERSION).tar.gz)
	$(call EXTRACT_TAR,m4-$(M4_VERSION).tar.gz,m4-$(M4_VERSION),m4)

ifneq ($(wildcard $(BUILD_WORK)/m4/.build_complete),)
m4:
	@echo "Using previously built m4."
else
m4: m4-setup
	cd $(BUILD_WORK)/m4 && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		gl_cv_func_posix_spawn_secure_exec=yes \
		gl_cv_func_posix_spawn_works=yes \
		gl_cv_func_posix_spawnp_secure_exec=yes
	+$(MAKE) -C $(BUILD_WORK)/m4
	+$(MAKE) -C $(BUILD_WORK)/m4 install \
		DESTDIR=$(BUILD_STAGE)/m4
	$(call AFTER_BUILD,copy)
endif
m4-package: m4-stage
	# m4.mk Package Structure
	rm -rf $(BUILD_DIST)/m4

	# m4.mk Prep m4
	cp -a $(BUILD_STAGE)/m4 $(BUILD_DIST)

	# m4.mk Sign
	$(call SIGN,m4,general.xml)

	# m4.mk Make .debs
	$(call PACK,m4,DEB_M4_V)

	# m4.mk Build cleanup
	rm -rf $(BUILD_DIST)/m4

.PHONY: m4 m4-package
