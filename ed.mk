ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += ed
ED_VERSION  := 1.17
DEB_ED_V    ?= $(ED_VERSION)

ed-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/ed/ed-$(ED_VERSION).tar.lz{,.sig}
	$(call PGP_VERIFY,ed-$(ED_VERSION).tar.lz)
	$(call EXTRACT_TAR,ed-$(ED_VERSION).tar.lz,ed-$(ED_VERSION),ed)

ifneq ($(wildcard $(BUILD_WORK)/ed/.build_complete),)
ed:
	@echo "Using previously built ed."
else
ed: ed-setup
	cd $(BUILD_WORK)/ed && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS) \
		CC=$(CC) \
		CFLAGS="$(CCFLAGS)" \
		CPPFLAGS="$(CPPFLAGS)" \
		LDFLAGS="$(LDFLAGS)"
	+$(MAKE) -C $(BUILD_WORK)/ed
	+$(MAKE) -C $(BUILD_WORK)/ed install -j1 \
		DESTDIR=$(BUILD_STAGE)/ed
	+$(MAKE) -C $(BUILD_WORK)/ed install -j1 \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/ed/.build_complete
endif
ed-package: ed-stage
	# ed.mk Package Structure
	rm -rf $(BUILD_DIST)/ed

	# ed.mk Prep ed
	cp -a $(BUILD_STAGE)/ed $(BUILD_DIST)

	# ed.mk Sign
	$(call SIGN,ed,general.xml)

	# ed.mk Make .debs
	$(call PACK,ed,DEB_ED_V)

	# ed.mk Build cleanup
	rm -rf $(BUILD_DIST)/ed

.PHONY: ed ed-package
