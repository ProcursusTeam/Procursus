ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPPROJECTS           += tcltk-defaults
TCLTK-DEFAULTS_VERSION := 8.6.12
DEB_TCLTK-DEFAULTS_V   ?= $(TCLTK-DEFAULTS_VERSION)

TCLTK_DEFAULT_VERSION   := 8.6

tcltk-defaults: setup
	@echo "Tcltk-defaults are just control files and symlinks."

tcltk-defaults-package: tcltk-defaults-stage
	# tcltk-defaults.mk Package Structure
	rm -rf $(BUILD_DIST)/t{cl,k}{,-dev,-doc}
	mkdir -p $(BUILD_DIST)/t{cl,k}{,-dev,-doc}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	mkdir -p $(BUILD_DIST)/t{cl,k}-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include,lib/pkgconfig}
	mkdir -p $(BUILD_DIST)/t{cl,k}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}

	# tcltk-defaults.mk Prep tcl
	$(LN_SR) $(BUILD_DIST)/tcl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/tclsh{8.6,}
	$(LN_SR) $(BUILD_DIST)/tcl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/tclsh{8.6,}.1$(MEMO_MANPAGE_SUFFIX)

	# tcltk-defaults Prep tcl-dev
	$(LN_SR) $(BUILD_DIST)/tcl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/tcl{8.6,}
	$(LN_SR) $(BUILD_DIST)/tcl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{tcl8.6/,}tclConfig.sh
	$(LN_SR) $(BUILD_DIST)/tcl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{tcl8.6/,}tclooConfig.sh
	$(LN_SR) $(BUILD_DIST)/tcl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtcl{8.6,}.a
	$(LN_SR) $(BUILD_DIST)/tcl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtclstub{8.6,}.a
	$(LN_SR) $(BUILD_DIST)/tcl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtcl{8.6,}.dylib
	$(LN_SR) $(BUILD_DIST)/tcl-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/tcl{8.6,}.pc

	# tcltk-defaults Prep tk
	$(LN_SR) $(BUILD_DIST)/tk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/wish{8.6,}
	$(LN_SR) $(BUILD_DIST)/tk/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/wish{8.6,}.1$(MEMO_MANPAGE_SUFFIX)

	# tcltk-defaults Prep tk-dev
	$(LN_SR) $(BUILD_DIST)/tk-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/{tcl8.6,tk} # yes, really tk -> tcl8.6
	$(LN_SR) $(BUILD_DIST)/tk-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtk{8.6,}.dylib
	$(LN_SR) $(BUILD_DIST)/tk-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtk{8.6,}.a
	$(LN_SR) $(BUILD_DIST)/tk-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtkstub{8.6,}.a
	$(LN_SR) $(BUILD_DIST)/tk-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/pkgconfig/tk{8.6,}.pc
	$(LN_SR) $(BUILD_DIST)/tk-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{tk8.6/,}/tkConfig.sh

	# tcltk-defaults.mk Make .debs
	$(call PACK,tcl,DEB_TCLTK-DEFAULTS_V)
	$(call PACK,tk,DEB_TCLTK-DEFAULTS_V)
	$(call PACK,tcl-dev,DEB_TCLTK-DEFAULTS_V)
	$(call PACK,tk-dev,DEB_TCLTK-DEFAULTS_V)
	$(call PACK,tcl-doc,DEB_TCLTK-DEFAULTS_V)
	$(call PACK,tk-doc,DEB_TCLTK-DEFAULTS_V)

	# tcltk-defaults.mk Build cleanup
	rm -rf $(BUILD_DIST)/t{cl,k}{,-dev,-doc}

.PHONY: tcltk-defaults tcltk-defaults-package
