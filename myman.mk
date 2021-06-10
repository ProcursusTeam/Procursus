ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += myman
MYMAN_VERSION := 2009-10-30
DEB_MYMAN_V   ?= 0.7.1

myman-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://downloads.sourceforge.net/project/myman/myman-cvs/myman-cvs-$(MYMAN_VERSION)/myman-wip-$(MYMAN_VERSION).tar.gz
	$(call EXTRACT_TAR,myman-wip-$(MYMAN_VERSION).tar.gz,myman-wip-$(MYMAN_VERSION),myman)

ifneq ($(wildcard $(BUILD_WORK)/myman/.build_complete),)
myman:
	@echo "Using previously built myman."
else
myman: myman-setup ncurses
	unset CC CFLAGS CXXFLAGS CPPFLAGS LDFLAGS && cd $(BUILD_WORK)/myman && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS)
	+unset CC CFLAGS CXXFLAGS CPPFLAGS LDFLAGS && $(MAKE) -C $(BUILD_WORK)/myman install \
		DESTDIR="$(BUILD_STAGE)/myman" \
		RMDIR="rmdir" \
		HOSTCC="$(CC)" \
		HOSTCFLAGS="$(CFLAGS)" \
		HOSTCPPFLAGS="$(CPPFLAGS)" \
		HOSTLDFLAGS="$(LDFLAGS)" \
		CURSESLIBS="-L$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib -lncursesw"
	touch $(BUILD_WORK)/myman/.build_complete
endif

myman-package: myman-stage
	# myman.mk Package Structure
	rm -rf $(BUILD_DIST)/myman

	# myman.mk Prep myman
	cp -a $(BUILD_STAGE)/myman $(BUILD_DIST)

	# myman.mk Sign
	$(call SIGN,myman,general.xml)

	# myman.mk Make .debs
	$(call PACK,myman,DEB_MYMAN_V)

	# myman.mk Build cleanup
	rm -rf $(BUILD_DIST)/myman

.PHONY: myman myman-package
