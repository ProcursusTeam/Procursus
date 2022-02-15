ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += tcl
TCL_VERSION := 8.6.12
DEB_TCL_V   ?= $(TCL_VERSION)

tcl-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) \
		https://nchc.dl.sourceforge.net/project/tcl/Tcl/$(TCL_VERSION)/tcl$(TCL_VERSION)-src.tar.gz
	$(call EXTRACT_TAR,tcl$(TCL_VERSION)-src.tar.gz,tcl$(TCL_VERSION),tcl)

ifneq ($(wildcard $(BUILD_WORK)/tcl/.build_complete),)
tcl:
	@echo "Using previously built tcl."
else
tcl: tcl-setup libtommath
	cd $(BUILD_WORK)/tcl && ./macosx/configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-load \
		--disable-rpath \
		--enable-langinfo
	sed -i 's@( cd $$(PKG_DIR)/$$$$pkg; $$(MAKE); ) || exit $$$$?; @( cd $$(PKG_DIR)/$$$$pkg; sed -i "s{--export-dynamic{{" $$$$(grep -riI -- "--export-dynamic" $(BUILD_WORK)/tcl/pkgs/$$$$pkg | cut -d: -f1) ;$$(MAKE); ) || exit $$$$?; @g' $(BUILD_WORK)/tcl/Makefile
	sed -i -e 's|-ltcl8.6|$(BUILD_WORK)/tcl/libtcl8.6.dylib|' -e 's/$${TCL_EXE}:/$${TCL_EXE}: manticore/' $(BUILD_WORK)/tcl/Makefile
	sed -i 's|# DO NOT DELETE THIS LINE -- make depend depends on it.|manticore: $${TCL_LIB_FILE} $${TCL_STUB_LIB_FILE}\n\t$$(CC) $$(CFLAGS) $$(LDFLAGS) -shared -install_name $$(MEMO_PREFIX)$$(MEMO_SUB_PREFIX)/lib/libtcl8.6.dylib -all_load -liosexec -lz -framework CoreFoundation libtcl8.6.a -o libtcl8.6.dylib;|' $(BUILD_WORK)/tcl/Makefile
	+$(MAKE) -C $(BUILD_WORK)/tcl install \
		DESTDIR=$(BUILD_STAGE)/tcl
	$(INSTALL) -m755 $(BUILD_WORK)/tcl/libtcl8.6.dylib $(BUILD_STAGE)/tcl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	$(call AFTER_BUILD,copy)
endif
tcl-package: tcl
	# tcl.mk Package Structure
	rm -rf $(BUILD_DIST)/{libtcl8.6,tcl8.6{,-dev,-doc}}
	mkdir -p $(BUILD_DIST)/{libtcl8.6,tcl8.6{,-dev,-doc}}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/{libtcl8.6,tcl8.6-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/tcl8.6
	mkdir -p $(BUILD_DIST)/{libtcl8.6,tcl8.6-doc}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	mkdir -p $(BUILD_DIST)/libtcl8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/tcltk
	
	# tcl.mk Prep tcl8.6
	cp -a $(BUILD_STAGE)/tcl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/tcl8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# tcl.mk Prep libtcl8.6
	cp -a $(BUILD_STAGE)/tcl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{itcl*,sqlite3*,tcl8,tcl8.6,tdbc{mysql,odbc,postgres}*,thread*} $(BUILD_DIST)/libtcl8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/tcltk
	cp -a $(BUILD_STAGE)/tcl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtcl{,stub}8.6.dylib $(BUILD_DIST)/libtcl8.6/$(MEMO_PREFIX)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	$(LN_SR) $(BUILD_DIST)/libtcl8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{share/tcltk,lib}/tcl8.6
	
	# tcl.mk Prep tcl8.6-dev
	cp -a $(BUILD_STAGE)/tcl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/tcl8.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -af $(BUILD_STAGE)/tcl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libtcl{,stub}8.6.a} $(BUILD_DIST)/tcl8.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/tcl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/tcl{,oo}Config.sh $(BUILD_DIST)/tcl8.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/tcl8.6
	
	# tcl.mk Prep tcl8.6-doc
	cp -a $(BUILD_STAGE)/tcl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/tcl8.6-doc/$(MEMO_SUB_PREFIX)
	
	# tcl.mk Sign
	$(call SIGN,tcl8.6,general.xml)
	$(call SIGN,libtcl8.6,general.xml)
	
	# tcl.mk Make .debs
	$(call PACK,tcl8.6,DEB_TCL_V)
	$(call PACK,tcl8.6-dev,DEB_TCL_V)
	$(call PACK,libtcl8.6,DEB_TCL_V)
	$(call PACK,tcl8.6-doc,DEB_TCL_V)
	
	# tcl.mk Build cleanup
	rm -rf $(BUILD_DIST)/{libtcl8.6,tcl8.6{,-dev,-doc}}

.PHONY: tcl tcl-package
