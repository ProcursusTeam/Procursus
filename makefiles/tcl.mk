ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += tcl
TCL_VERSION := 8.6.11
DEB_TCL_V   ?= $(TCL_VERSION)

tcl-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) \
	      	http://deb.debian.org/debian/pool/main/t/tcl8.6/tcl8.6_$(TCL_VERSION)+dfsg.orig.tar.gz
	$(call EXTRACT_TAR,tcl8.6_$(TCL_VERSION)+dfsg.orig.tar.gz,tcl$(TCL_VERSION),tcl)

ifneq ($(wildcard $(BUILD_WORK)/tcl/.build_complete),)
tcl:
	@echo "Using previously built tcl."
else
tcl: tcl-setup
	cd $(BUILD_WORK)/tcl && ./macosx/configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--disable-load
	+$(MAKE) -C $(BUILD_WORK)/tcl
	+$(MAKE) -C $(BUILD_WORK)/tcl install \
		DESTDIR=$(BUILD_STAGE)/tcl
	$(call AFTER_BUILD,copy)
endif

tcl-package: tcl-stage
	# tcl.mk Package Structure
	rm -rf $(BUILD_DIST)/{libtcl8.6,tcl8.6{,-dev-doc}}
	mkdir -p $(BUILD_DIST)/{libtcl8.6,tcl8.6{,-dev-doc}}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/{libtcl8.6,tcl8.6-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/tcl
	mkdir -p $(BUILD_DIST)/{libtcl8.6,tcl8.6-doc}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share
	mkdir -p $(BUILD_DIST)/libtcl8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/tcltk
	
	# tcl.mk Prep tcl8.6
	cp -a $(BUILD_STAGE)/tcl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/tcl8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# tcl.mk Prep libtcl8.6
	cp -a $(BUILD_STAGE)/tcl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/tcl8.6 $(BUILD_DIST)/libtcl8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/tcltk
	$(LN_SR) $(BUILD_DIST)/libtcl8.6/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{share/tcltk,lib}/tcl8.6

	# tcl.mk Prep tcl8.6-dev
	cp -a $(BUILD_STAGE)/tcl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/tcl8.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	cp -af $(BUILD_STAGE)/tcl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libtclstub8.6.a,libtcl8.6.a,tclConfig.sh,tclooConfig.sh} $(BUILD_DIST)/tcl8.6-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# tcl.mk Prep tcl8.6-doc
	cp -a $(BUILD_STAGE)/tcl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share $(BUILD_DIST)/$(MEMO_SUB_PREFIX)
	
	# tcl.mk Sign
	$(call SIGN,tcl8.6,general.xml)
	
	# tcl.mk Make .debs
	$(call PACK,tcl8.6,DEB_TCL_V)
	$(call PACK,tcl8.6-dev,DEB_TCL_V)
	$(call PACK,libtcl8.6,DEB_TCL_V)
	$(call PACK,tcl8.6-doc,DEB_TCL_V)
	
	# tcl.mk Build cleanup
	rm -rf $(BUILD_DIST)/{libtcl8.6,tcl8.6{,-dev-doc}}

.PHONY: tcl tcl-package
