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
tcl: tcl-setup
	cd $(BUILD_WORK)/tcl && ./macosx/configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-load
	sed -i 's@( cd $$(PKG_DIR)/$$$$pkg; $$(MAKE); ) || exit $$$$?; @( cd $$(PKG_DIR)/$$$$pkg; sed -i "s{--export-dynamic{{" $$$$(grep -riI -- "--export-dynamic" $(BUILD_WORK)/tcl/pkgs/$$$$pkg | cut -d: -f1) ;$$(MAKE); ) || exit $$$$?; @g' $(BUILD_WORK)/tcl/Makefile
	+$(MAKE) -C $(BUILD_WORK)/tcl
	+$(MAKE) -C $(BUILD_WORK)/tcl install \
		DESTDIR=$(BUILD_STAGE)/tcl
	$(call AFTER_BUILD,copy)
endif
tcl-package: tcl
	# tcl.mk Package Structure
	rm -rf $(BUILD_DIST)/{libtcl8.6,tcl8.6{,-dev,-doc}}
	mkdir -p $(BUILD_DIST)/{libtcl8.6,tcl8.6{,-dev,-doc}}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/{libtcl8.6,tcl8.6-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/tcl
	mkdir -p $(BUILD_DIST)/{libtcl8.6,tcl8.6-doc}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	mkdir -p $(BUILD_DIST)/libtcl8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/tcltk
	
	# tcl.mk Prep tcl8.6
	cp -a $(BUILD_STAGE)/tcl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/tcl8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# tcl.mk Prep libtcl8.6
	cp -a $(BUILD_STAGE)/tcl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{itcl4.2.2,sqlite3.36.0,tcl8,tcl8.6,tdbc{mysql,odbc,postgres}1.1.3,thread2.8.7} $(BUILD_DIST)/libtcl8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/tcltk
	$(LN_SR) $(BUILD_DIST)/libtcl8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{share/tcltk,lib}/tcl8.6
	
	# tcl.mk Prep tcl8.6-dev
	cp -a $(BUILD_STAGE)/tcl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/tcl8.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -af $(BUILD_STAGE)/tcl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libtclstub8.6.a,libtcl8.6.a,tclConfig.sh,tclooConfig.sh} $(BUILD_DIST)/tcl8.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# tcl.mk Prep tcl8.6-doc
	cp -a $(BUILD_STAGE)/tcl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/tcl8.6-doc/$(MEMO_SUB_PREFIX)
	
	# tcl.mk Sign
	$(call SIGN,tcl8.6,general.xml)
	
	# tcl.mk Make .debs
	$(call PACK,tcl8.6,DEB_TCL_V)
	$(call PACK,tcl8.6-dev,DEB_TCL_V)
	$(call PACK,libtcl8.6,DEB_TCL_V)
	$(call PACK,tcl8.6-doc,DEB_TCL_V)
	
	# tcl.mk Build cleanup
	rm -rf $(BUILD_DIST)/{libtcl8.6,tcl8.6{,-dev,-doc}}

.PHONY: tcl tcl-package
