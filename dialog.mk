ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += dialog
DIALOG_VERSION := 1.3
DIALOG_DATE    := 20210117
DEB_DIALOG_V   ?= $(DIALOG_VERSION)-$(DIALOG_DATE)

dialog-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://invisible-mirror.net/archives/dialog/dialog-$(DIALOG_VERSION)-$(DIALOG_DATE).tgz
	$(call EXTRACT_TAR,dialog-$(DIALOG_VERSION)-$(DIALOG_DATE).tgz,dialog-$(DIALOG_VERSION)-$(DIALOG_DATE),dialog)

ifneq ($(wildcard $(BUILD_WORK)/dialog/.build_complete),)
dialog:
	@echo "Using previously built dialog."
else
dialog: dialog-setup ncurses gettext
	cd $(BUILD_WORK)/dialog && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-ncursesw \
		--enable-nls
	+$(MAKE) -C $(BUILD_WORK)/dialog
	+$(MAKE) -C $(BUILD_WORK)/dialog install-full \
		DESTDIR=$(BUILD_STAGE)/dialog
	touch $(BUILD_WORK)/dialog/.build_complete
endif

dialog-package: dialog-stage
	# dialog.mk Package Structure
	rm -rf $(BUILD_DIST)/dialog
	mkdir -p $(BUILD_DIST)/dialog

	# dialog.mk Prep dialog
	# To keep parity with debian, dialog is not
	# being split, it also is only having a static
	# lib. I can't install the headers without
	# dialog-config so that gets deleted here.
	cp -a $(BUILD_STAGE)/dialog $(BUILD_DIST)
	rm $(BUILD_DIST)/dialog/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/dialog-config

	# dialog.mk Sign
	$(call SIGN,dialog,general.xml)

	# dialog.mk Make .debs
	$(call PACK,dialog,DEB_DIALOG_V)

	# dialog.mk Build cleanup
	rm -rf $(BUILD_DIST)/dialog

.PHONY: dialog dialog-package
