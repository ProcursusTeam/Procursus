ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += tk
TK_VERSION  := 8.6.12
DEB_TK_V    ?= $(TK_VERSION)

tk-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://nchc.dl.sourceforge.net/project/tcl/Tcl/$(TK_VERSION)/tk$(TK_VERSION)-src.tar.gz
	$(call EXTRACT_TAR,tk$(TK_VERSION)-src.tar.gz,tk$(TK_VERSION),tk)

ifneq ($(wildcard $(BUILD_WORK)/tk/.build_complete),)
tk:
	@echo "Using previously built tk."
else
tk: tk-setup tcl libxss libx11 libxext libxft xorgproto freetype fontconfig
	cd $(BUILD_WORK)/tk && ./macosx/configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-tcl=$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		--with-x \
		--disable-load
	sed -i -e 's|-ltk8.6|$(BUILD_WORK)/tk/libtk8.6.dylib|' -e 's/$${WISH_EXE}:/$${WISH_EXE}: mantiscam/' $(BUILD_WORK)/tk/Makefile
	sed -i 's|# DO NOT DELETE THIS LINE -- make depend depends on it.|mantiscam: $${TK_LIB_FILE} $${TK_STUB_LIB_FILE}\n\t$$(CC) $$(CFLAGS) $$(LDFLAGS) -shared -install_name $$(MEMO_PREFIX)$$(MEMO_SUB_PREFIX)/lib/libtk8.6.dylib -all_load -lX11 -lXss -lXft -lfontconfig -ltcl8.6 libtk8.6.a -o libtk8.6.dylib;|' $(BUILD_WORK)/tk/Makefile
	+$(MAKE) -C $(BUILD_WORK)/tk
	+$(MAKE) -C $(BUILD_WORK)/tk install \
		DESTDIR=$(BUILD_STAGE)/tk
	install -m755 $(BUILD_WORK)/tk/libtk8.6.dylib $(BUILD_STAGE)/tk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	$(call AFTER_BUILD,copy)
endif

tk-package: tk-stage
	# tk.mk Package Structure
	rm -rf $(BUILD_DIST)/{tk8.6,libtk8.6,tk8.6-dev,tk8.6-doc}
	mkdir -p $(BUILD_DIST)/{tk8.6,libtk8.6,tk8.6-dev,tk8.6-doc}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/{libtk8.6,tk8.6-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,share/tcltk}

	# tk.mk Prep tk8.6
	cp -a $(BUILD_STAGE)/tk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/tk8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# tk.mk Prep libtk8.6
	cp -a $(BUILD_STAGE)/tk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/tk8.6 $(BUILD_DIST)/libtk8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/tcltk
	cp -a $(BUILD_STAGE)/tk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtk8.6.dylib $(BUILD_DIST)/libtk8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	$(LN_SR) $(BUILD_DIST)/libtk8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{share/tcltk,lib}/tk8.6

	# tk.mk Prep tk8.6-dev
	cp -a $(BUILD_STAGE)/tk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/tk8.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -a $(BUILD_STAGE)/tk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libtk{,stub}8.6.a,pkgconfig} $(BUILD_DIST)/tk8.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/tk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/tkConfig.sh $(BUILD_DIST)/tk8.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/tcltk/tk8.6

	# tk.mk Prep tk8.6-doc
	cp -a $(BUILD_STAGE)/tk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/tk8.6-doc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# tk.mk Sign
	$(call SIGN,tk8.6,general.xml)

	# tk.mk Make .debs
	$(call PACK,tk8.6,DEB_TK_V)
	$(call PACK,libtk8.6,DEB_TK_V)
	$(call PACK,tk8.6-dev,DEB_TK_V)
	$(call PACK,tk8.6-doc,DEB_TK_V)

	# tk.mk Build cleanup
	rm -rf $(BUILD_DIST)/{tk8.6,libtk8.6,tk8.6-dev,tk8.6-doc}

.PHONY: tk tk-package
