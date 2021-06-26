ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += cwidget
CWIDGET_VERSION := 0.5.18
DEB_CWIDGET_V   ?= $(CWIDGET_VERSION)

cwidget-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://salsa.debian.org/cwidget-team/cwidget-upstream/-/archive/$(CWIDGET_VERSION)/cwidget-upstream-$(CWIDGET_VERSION).tar.gz
	$(call EXTRACT_TAR,cwidget-upstream-$(CWIDGET_VERSION).tar.gz,cwidget-upstream-$(CWIDGET_VERSION),cwidget)
	$(SED) -i '/#define THREADS_H/a #include <pthread.h>' $(BUILD_WORK)/cwidget/src/cwidget/generic/threads/threads.h

ifneq ($(wildcard $(BUILD_WORK)/cwidget/.build_complete),)
cwidget:
	@echo "Using previously built cwidget."
else
cwidget: cwidget-setup gettext ncurses libsigcplusplus
	rm -rf $(BUILD_WORK)/cwidget/m4/{libtool,lt*}.m4
	$(SED) -i 's/libtoolize/$(LIBTOOLIZE)/' $(BUILD_WORK)/cwidget/autogen.sh
	cd $(BUILD_WORK)/cwidget && ./autogen.sh \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-werror \
		CXXFLAGS="-std=c++11 $(CXXFLAGS) -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/sigc++-2.0 -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/sigc++-2.0/include -DNCURSES_WIDECHAR"
	+$(MAKE) -C $(BUILD_WORK)/cwidget \
		LIBS="-lncursesw  -lpthread -lsigc-2.0 -liconv -lintl -Wl,-framework -Wl,CoreFoundation"
	+$(MAKE) -C $(BUILD_WORK)/cwidget install \
		DESTDIR="$(BUILD_STAGE)/cwidget"
	+$(MAKE) -C $(BUILD_WORK)/cwidget install \
		DESTDIR="$(BUILD_BASE)"
	touch $(BUILD_WORK)/cwidget/.build_complete
endif

cwidget-package: cwidget-stage
	# cwidget.mk Package Structure
	rm -rf $(BUILD_DIST)/*cwidget*/
	mkdir -p $(BUILD_DIST)/libcwidget4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libcwidget-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# cwidget.mk Prep libcwidget4
	cp -a $(BUILD_STAGE)/cwidget/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/lib*.4.dylib $(BUILD_DIST)/libcwidget4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/cwidget/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/libcwidget4/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# cwidget.mk Prep libcwidget-dev
	cp -a $(BUILD_STAGE)/cwidget/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libcwidget-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/cwidget/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/!(*.4.*) $(BUILD_DIST)/libcwidget-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# cwidget.mk Sign
	$(call SIGN,libcwidget4,general.xml)

	# cwidget.mk Make .debs
	$(call PACK,libcwidget4,DEB_CWIDGET_V)
	$(call PACK,libcwidget-dev,DEB_CWIDGET_V)

	# cwidget.mk Build cleanup
	rm -rf $(BUILD_DIST)/*cwidget*/

.PHONY: cwidget cwidget-package
