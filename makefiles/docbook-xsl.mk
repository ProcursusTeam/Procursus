ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += docbook-xsl
# Change the docbook-xsl and docbook-xsl-ns install scripts on version update.
DOCBOOK-XSL_VERSION := 1.79.2
DEB_DOCBOOK-XSL_V   ?= $(DOCBOOK-XSL_VERSION)

docbook-xsl-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) \
		https://github.com/docbook/xslt10-stylesheets/releases/download/release%2F$(DOCBOOK-XSL_VERSION)/docbook-xsl-nons-$(DOCBOOK-XSL_VERSION).tar.bz2 \
		https://github.com/docbook/xslt10-stylesheets/releases/download/release%2F$(DOCBOOK-XSL_VERSION)/docbook-xsl-$(DOCBOOK-XSL_VERSION).tar.bz2
	$(call EXTRACT_TAR,docbook-xsl-$(DOCBOOK-XSL_VERSION).tar.bz2,docbook-xsl-$(DOCBOOK-XSL_VERSION),docbook-xsl/docbook-xsl-ns)
	$(call EXTRACT_TAR,docbook-xsl-nons-$(DOCBOOK-XSL_VERSION).tar.bz2,docbook-xsl-nons-$(DOCBOOK-XSL_VERSION),docbook-xsl/docbook-xsl)
	$(call DO_PATCH,docbook-xsl,docbook-xsl/docbook-xsl-ns,-p1)

ifneq ($(wildcard $(BUILD_WORK)/docbook-xsl/.build_complete),)
docbook-xsl:
	@echo "Using previously built docbook-xsl."
else
docbook-xsl: docbook-xsl-setup
	for xsl in docbook-xsl{,-ns}; do                                                                                                  \
		cd $(BUILD_WORK)/docbook-xsl/$${xsl} &&                                                                                       \
		install -v -m755 -d $(BUILD_STAGE)/docbook-xsl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/xml/docbook/stylesheet/$${xsl} &&       \
		cp -v -R VERSION assembly catalog.xml common eclipse epub epub3 extensions                                                    \
				fo highlighting html htmlhelp images javahelp lib manpages params                                                     \
				profiling roundtrip slides template tests tools webhelp website                                                       \
				xhtml xhtml-1_1 xhtml5                                                                                                \
			$(BUILD_STAGE)/docbook-xsl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/xml/docbook/stylesheet/$${xsl} &&                       \
		ln -s VERSION $(BUILD_STAGE)/docbook-xsl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/xml/docbook/stylesheet/$${xsl}/VERSION.xsl && \
		install -v -m644 -D README                                                                                                    \
			$(BUILD_STAGE)/docbook-xsl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc/$${xsl}/README.txt &&                               \
		install -v -m644    RELEASE-NOTES* NEWS*                                                                                      \
			$(BUILD_STAGE)/docbook-xsl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc/$${xsl};                                            \
	done
	install -v -m755 -d $(BUILD_STAGE)/docbook-xsl/$(MEMO_PREFIX)/etc/xml
	touch $(BUILD_WORK)/docbook-xsl/.build_complete
endif
docbook-xsl-package: docbook-xsl-stage
	# docbook-xsl.mk Package Structure
	rm -rf $(BUILD_DIST)/docbook-xsl{,-ns}
	mkdir -p $(BUILD_DIST)/docbook-xsl{,-ns}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/{doc,xml/docbook/stylesheet}

	# docbook-xsl.mk Prep docbook-xsl
	cp -a $(BUILD_STAGE)/docbook-xsl/$(MEMO_PREFIX)/etc $(BUILD_DIST)/docbook-xsl/$(MEMO_PREFIX)
	cp -a $(BUILD_STAGE)/docbook-xsl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/xml/docbook/stylesheet/docbook-xsl $(BUILD_DIST)/docbook-xsl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/xml/docbook/stylesheet
	cp -a $(BUILD_STAGE)/docbook-xsl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc/docbook-xsl $(BUILD_DIST)/docbook-xsl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc

	# docbook-xsl.mk Prep docbook-xsl-ns
	cp -a $(BUILD_STAGE)/docbook-xsl/$(MEMO_PREFIX)/etc $(BUILD_DIST)/docbook-xsl-ns/$(MEMO_PREFIX)
	cp -a $(BUILD_STAGE)/docbook-xsl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/xml/docbook/stylesheet/docbook-xsl-ns $(BUILD_DIST)/docbook-xsl-ns/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/xml/docbook/stylesheet
	cp -a $(BUILD_STAGE)/docbook-xsl/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc/docbook-xsl-ns $(BUILD_DIST)/docbook-xsl-ns/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/doc

	# docbook-xsl.mk Make .debs
	$(call PACK,docbook-xsl,DEB_DOCBOOK-XSL_V)
	$(call PACK,docbook-xsl-ns,DEB_DOCBOOK-XSL_V)

	# docbook-xsl.mk Build cleanup
	rm -rf $(BUILD_DIST)/docbook-xsl{,-ns}

.PHONY: docbook-xsl docbook-xsl-package
