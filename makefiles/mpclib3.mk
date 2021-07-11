ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += mpclib3
MPCLIB3_VERSION := 1.2.1
DEB_MPCLIB3_V   ?= $(MPCLIB3_VERSION)

mpclib3-setup: setup
	wget -q -np -P $(BUILD_SOURCE) https://ftp.gnu.org/gnu/mpc/mpc-$(MPCLIB3_VERSION).tar.gz
	$(call EXTRACT_TAR,mpc-$(MPCLIB3_VERSION).tar.gz,mpc-$(MPCLIB3_VERSION),mpclib3)

ifneq ($(wildcard $(BUILD_WORK)/mpclib3/.build_complete),)
mpclib3:
	@echo "Using previously built mpclib3."
else
mpclib3: mpclib3-setup libgmp10 mpfr4
	cd $(BUILD_WORK)/mpclib3 && ./configure \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/mpclib3
	+$(MAKE) -C $(BUILD_WORK)/mpclib3 install \
		DESTDIR="$(BUILD_STAGE)/mpclib3"
	+$(MAKE) -C $(BUILD_WORK)/mpclib3 install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/mpclib3/.build_complete
endif

mpclib3-package: mpclib3-stage
	# mpclib3.mk Package Structure
	rm -rf $(BUILD_DIST)/libmpc{3,-dev}
	mkdir -p $(BUILD_DIST)/libmpc{3,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# mpclib3.mk Prep libmpc3
	cp -a $(BUILD_STAGE)/mpclib3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libmpc.3.dylib $(BUILD_DIST)/libmpc3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# mpclib3.mk Prep libmpc-dev
	cp -a $(BUILD_STAGE)/mpclib3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(libmpc.3.dylib) $(BUILD_DIST)/libmpc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/mpclib3/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libmpc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# mpclib3.mk Sign
	$(call SIGN,libmpc3,general.xml)

	# mpclib3.mk Make .debs
	$(call PACK,libmpc3,DEB_MPCLIB3_V)
	$(call PACK,libmpc-dev,DEB_MPCLIB3_V)

	# mpclib3.mk Build cleanup
	rm -rf $(BUILD_DIST)/libmpc{3,-dev}

.PHONY: mpclib3 mpclib3-package
