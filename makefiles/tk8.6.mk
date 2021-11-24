ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += tk8.6
TK8.6_VERSION := 8.6.12
DEB_TK8.6_V   ?= $(TK8.6_VERSION)

tk8.6-setup: setup
	-[ ! -f $(BUILD_SOURCE)/tk8.6-$(TK8.6_VERSION).tar.gz ] && \
	      	wget -q -nc -O$(BUILD_SOURCE)/tk8.6-$(TK8.6_VERSION).tar.gz \
	      		https://nchc.dl.sourceforge.net/project/tcl/Tcl/$(TK8.6_VERSION)/tk$(TK8.6_VERSION)-src.tar.gz
	$(call EXTRACT_TAR,tk8.6-$(TK8.6_VERSION).tar.gz,tk$(TK8.6_VERSION),tk8.6)

ifneq ($(wildcard $(BUILD_WORK)/tk8.6/.build_complete),)
tk8.6:
	@echo "Using previously built tk8.6."
else
tk8.6: tk8.6-setup tcl libxss libx11 libxext libxft xorgproto freetype fontconfig
	cd $(BUILD_WORK)/tk8.6 && ./macosx/configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-tcl=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		--with-x \
		--disable-load
	+$(MAKE) -C $(BUILD_WORK)/tk8.6
	+$(MAKE) -C $(BUILD_WORK)/tk8.6 install \
		DESTDIR=$(BUILD_STAGE)/tk8.6
	$(call AFTER_BUILD,copy)
endif

tk8.6-package: tk8.6-stage
	# tk8.6.mk Package Structure
	rm -rf $(BUILD_DIST)/{tk8.6,libtk8.6,tk8.6-dev,tk8.6-doc}
	mkdir -p $(BUILD_DIST)/{tk8.6,libtk8.6,tk8.6-dev,tk8.6-doc}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/{libtk8.6,tk8.6-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	mkdir -p $(BUILD_DIST)/libtk8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/tcltk

	# tk8.6.mk Prep tk8.6
	cp -a $(BUILD_STAGE)/tk8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/tk8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# tk8.6.mk Prep libtk8.6
	cp -a $(BUILD_STAGE)/tk8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/tk8.6 $(BUILD_DIST)/libtk8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/tcltk
	$(LN_SR) $(BUILD_DIST)/libtk8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{share/tcltk,lib}/tk8.6

	# tk8.6.mk Prep tk8.6-dev
	cp -a $(BUILD_STAGE)/tk8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/tk8.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/tk8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{tkConfig.sh,libtk{,stub}8.6.a,pkgconfig} $(BUILD_DIST)/tk8.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# tk8.6.mk Prep tk8.6-doc
	cp -a $(BUILD_STAGE)/tk8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/tk8.6-doc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# tk8.6.mk Sign
	$(call SIGN,tk8.6,general.xml)

	# tk8.6.mk Make .debs
	$(call PACK,tk8.6,DEB_TK8.6_V)
	$(call PACK,libtk8.6,DEB_TK8.6_V)
	$(call PACK,tk8.6-dev,DEB_TK8.6_V)
	$(call PACK,tk8.6-doc,DEB_TK8.6_V)

	# tk8.6.mk Build cleanup
	rm -rf $(BUILD_DIST)/{tk8.6,libtk8.6,tk8.6-dev,tk8.6-doc}

.PHONY: tk8.6 tk8.6-package
