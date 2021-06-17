ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += gtk-doc
GTK_DOC_VERSION := 1.32
DEB_GTK_DOC_V   ?= $(GTK_DOC_VERSION)-1

gtk-doc-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://download.gnome.org/sources/gtk-doc/$(GTK_DOC_VERSION)/gtk-doc-$(GTK_DOC_VERSION).tar.xz
	$(call EXTRACT_TAR,gtk-doc-$(GTK_DOC_VERSION).tar.xz,gtk-doc-$(GTK_DOC_VERSION),gtk-doc)

ifneq ($(wildcard $(BUILD_WORK)/gtk-doc/.build_complete),)
gtk-doc:
	@echo "Using previously built gtk-doc."
else
gtk-doc: gtk-doc-setup
	cd $(BUILD_WORK)/gtk-doc && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-xml-catalog="$(XML_CATALOG_FILES)"
	+$(MAKE) -C $(BUILD_WORK)/gtk-doc
	+$(MAKE) -C $(BUILD_WORK)/gtk-doc install \
		DESTDIR=$(BUILD_STAGE)/gtk-doc
	$(SED) -i "s|$$(cat $(BUILD_STAGE)/gtk-doc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/gtkdoc-check | grep \#! | sed 's/#!//')|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3|" $(BUILD_STAGE)/gtk-doc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*
	$(SED) -i "s|$(BUILD_TOOLS)/.*-pkg-config|$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pkg-config|" $(BUILD_STAGE)/gtk-doc/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin/gtkdoc-depscan,share/gtk-doc/python/gtkdoc/config.py}
	touch $(BUILD_WORK)/gtk-doc/.build_complete
endif

gtk-doc-package: gtk-doc-stage
	# gtk-doc.mk Package Structure
	rm -rf $(BUILD_DIST)/gtk-doc-tools
	
	# gtk-doc.mk Prep gtk-doc-tools
	cp -a $(BUILD_STAGE)/gtk-doc $(BUILD_DIST)/gtk-doc-tools
	
	# gtk-doc.mk Sign
	$(call SIGN,gtk-doc-tools,general.xml)
	
	# gtk-doc.mk Make .debs
	$(call PACK,gtk-doc-tools,DEB_GTK_DOC_V)
	
	# gtk-doc.mk Build cleanup
	rm -rf $(BUILD_DIST)/gtk-doc-tools

.PHONY: gtk-doc gtk-doc-package
