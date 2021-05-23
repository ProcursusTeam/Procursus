ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += docbook-xml
# Change the docbook-xml install script on version update.
DOCBOOK-XML_VERSION := 4.5
DEB_DOCBOOK-XML_V   ?= $(DOCBOOK-XML_VERSION)

docbook-xml-setup: setup
	mkdir -p $(BUILD_WORK)/docbook-xml
	for ver in 4.2 4.3 4.4 $(DOCBOOK-XML_VERSION); do \
		wget -q -nc -P $(BUILD_SOURCE) https://docbook.org/xml/$${ver}/docbook-xml-$${ver}.zip; \
		rm -rf $(BUILD_WORK)/docbook-xml/$${ver}; \
		unzip $(BUILD_SOURCE)/docbook-xml-$${ver}.zip -d $(BUILD_WORK)/docbook-xml/$${ver}; \
	done

ifneq ($(wildcard $(BUILD_WORK)/docbook-xml/.build_complete),)
docbook-xml:
	@echo "Using previously built docbook-xml."
else
docbook-xml: docbook-xml-setup
	for ver in 4.2 4.3 4.4 $(DOCBOOK-XML_VERSION); do                                                                          \
		cd $(BUILD_WORK)/docbook-xml/$${ver} &&                                                                                 \
		install -v -d -m755 $(BUILD_STAGE)/docbook-xml/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/xml/docbook/schema/dtd/$${ver} && \
		cp -v -af docbook.cat *.dtd ent/ *.mod catalog.xml                                                                                \
			$(BUILD_STAGE)/docbook-xml/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/xml/docbook/schema/dtd/$${ver};                   \
	done
	install -v -d -m755 $(BUILD_STAGE)/docbook-xml/$(MEMO_PREFIX)/etc/xml
	touch $(BUILD_WORK)/docbook-xml/.build_complete
endif
docbook-xml-package: docbook-xml-stage
	# docbook-xml.mk Package Structure
	rm -rf $(BUILD_DIST)/docbook-xml

	# docbook-xml.mk Prep docbook-xml
	cp -a $(BUILD_STAGE)/docbook-xml $(BUILD_DIST)

	# docbook-xml.mk Make .debs
	$(call PACK,docbook-xml,DEB_DOCBOOK-XML_V)

	# docbook-xml.mk Build cleanup
	rm -rf $(BUILD_DIST)/docbook-xml

.PHONY: docbook-xml docbook-xml-package
