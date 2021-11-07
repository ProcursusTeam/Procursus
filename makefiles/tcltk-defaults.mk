ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPPROJECTS           += tcltk-defaults
TCLTK-DEFAULTS_VERSION := 8.6.12
DEB_TCLTK-DEFAULTS_V   ?= $(TCLTK-DEFAULTS_VERSION)

tcltk-defaults: setup
	@echo "Tcltk-defaults are just control files."

tcltk-defaults-package: tcltk-defaults-stage
	# tcltk-defaults.mk Package Structure
	rm -rf $(BUILD_DIST)/t{cl,k}{,-dev,doc}
	mkdir -p $(BUILD_DIST)/t{cl,k}{,-dev,doc}

	# tcltk-defaults.mk Make .debs
	$(call PACK,tcl,DEB_TCLTK-DEFAULTS_V)
	$(call PACK,tk,DEB_TCLTK-DEFAULTS_V)
	$(call PACK,tcl-dev,DEB_TCLTK-DEFAULTS_V)
	$(call PACK,tk-dev,DEB_TCLTK-DEFAULTS_V)
	$(call PACK,tcl-doc,DEB_TCLTK-DEFAULTS_V)
	$(call PACK,tk-doc,DEB_TCLTK-DEFAULTS_V)

	# tcltk-defaults.mk Build cleanup
	rm -rf $(BUILD_DIST)/t{cl,k}{,-dev,doc}

.PHONY: tcltk-defaults tcltk-defaults-package
