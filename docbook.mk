ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   	 += docbook
DOCBOOK_VERSION  := 5.1
DEB_DOCBOOK_V	 ?= $(DOCBOOK_VERSION)
# $(shell declare -a XML_VERSION)
XML_VERSION0 := 4.1.2
XML_VERSION1 := 412
XML_VERSION2 := 4.2
XML_VERSION3 := 4.3
XML_VERSION4 := 4.4
XML_VERSION5 := 4.5
XML_VERSION6 := 5.0
XML_VERSION7 := 5.1
XML_CATALOG_DIR := $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/etc/xml
XML_CATALOG_FILES := $(XML_CATALOG_DIR)/catalog
# XML_VERSION := 4.2 4.3 4.4 4.5 5.0 4.1.2 412 5.1

docbook-setup: setup
	# VAR1=0
	# for VAR in ${XML_VERSION}; do
	# 	if [[ $(VAR1) -lt 4 ]]; then
	# 		wget -q -nc -P $(BUILD_SOURCE) https://docbook.org/xml/$(VAR)/docbook-xml-$(VAR).zip
	# 	fi
	# 	((VAR1++))
	# done
	wget -q -nc -P $(BUILD_SOURCE) https://docbook.org/xml/$(XML_VERSION0)/docbkx$(XML_VERSION1).zip
	wget -q -nc -P $(BUILD_SOURCE) https://docbook.org/xml/$(XML_VERSION2)/docbook-xml-$(XML_VERSION2).zip
	wget -q -nc -P $(BUILD_SOURCE) https://docbook.org/xml/$(XML_VERSION3)/docbook-xml-$(XML_VERSION3).zip
	wget -q -nc -P $(BUILD_SOURCE) https://docbook.org/xml/$(XML_VERSION4)/docbook-xml-$(XML_VERSION4).zip
	wget -q -nc -P $(BUILD_SOURCE) https://docbook.org/xml/$(XML_VERSION5)/docbook-xml-$(XML_VERSION5).zip
	wget -q -nc -P $(BUILD_SOURCE) https://docbook.org/xml/$(XML_VERSION6)/docbook-$(XML_VERSION6).zip
	wget -q -nc -P $(BUILD_SOURCE) https://docbook.org/xml/$(XML_VERSION7)/docbook-v$(XML_VERSION7)-os.zip

	mkdir -p $(BUILD_WORK)/docbook/xml/{$(XML_VERSION0),$(XML_VERSION2),$(XML_VERSION3),$(XML_VERSION4),$(XML_VERSION5),$(XML_VERSION6),$(XML_VERSION7)}

	unzip -qo $(BUILD_SOURCE)/docbkx$(XML_VERSION1).zip -d $(BUILD_WORK)/docbook/xml/$(XML_VERSION0)
	unzip -qo $(BUILD_SOURCE)/docbook-xml-$(XML_VERSION2).zip -d $(BUILD_WORK)/docbook/xml/$(XML_VERSION2)
	unzip -qo $(BUILD_SOURCE)/docbook-xml-$(XML_VERSION3).zip -d $(BUILD_WORK)/docbook/xml/$(XML_VERSION3)
	unzip -qo $(BUILD_SOURCE)/docbook-xml-$(XML_VERSION4).zip -d $(BUILD_WORK)/docbook/xml/$(XML_VERSION4)
	unzip -qo $(BUILD_SOURCE)/docbook-xml-$(XML_VERSION5).zip -d $(BUILD_WORK)/docbook/xml/$(XML_VERSION5)
	unzip -qo $(BUILD_SOURCE)/docbook-$(XML_VERSION6).zip -d $(BUILD_WORK)/docbook/xml/$(XML_VERSION6)
	unzip -qo $(BUILD_SOURCE)/docbook-v$(XML_VERSION7)-os.zip -d $(BUILD_WORK)/docbook/xml/$(XML_VERSION7)

ifneq ($(wildcard $(BUILD_WORK)/docbook/.build_complete),)
docbook:
	@echo "Using previously built docbook."
else
docbook: docbook-setup
	mkdir -p $(BUILD_STAGE)/docbook$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/opt/docbook
	cp -r $(BUILD_WORK)/docbook/xml $(BUILD_STAGE)/docbook$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/opt/docbook
	cp $(BUILD_STAGE)/docbook$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/opt/docbook/xml/$(XML_VERSION2)/catalog.xml $(BUILD_STAGE)/docbook$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/opt/docbook/xml/$(XML_VERSION0)
	$(SED) -i 's/${XML_VERSION2}/${XML_VERSION0}/g' $(BUILD_STAGE)/docbook$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/opt/docbook/xml/$(XML_VERSION0)/catalog.xml
	rm -r $(BUILD_STAGE)/docbook$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/opt/docbook/xml/$(XML_VERSION6)/docbook-$(XML_VERSION6)/docs
	mkdir -p $(BUILD_STAGE)/docbook$(XML_CATALOG_DIR)
	
	xmlcatalog --noout --create $(BUILD_STAGE)/docbook$(XML_CATALOG_FILES)

	xmlcatalog --noout --del file://$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/opt/docbook/xml/$(XML_VERSION0)/catalog.xml $(BUILD_STAGE)/docbook$(XML_CATALOG_FILES)
	xmlcatalog --noout --del file://$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/opt/docbook/xml/$(XML_VERSION2)/catalog.xml $(BUILD_STAGE)/docbook$(XML_CATALOG_FILES)
	xmlcatalog --noout --del file://$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/opt/docbook/xml/$(XML_VERSION3)/catalog.xml $(BUILD_STAGE)/docbook$(XML_CATALOG_FILES)
	xmlcatalog --noout --del file://$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/opt/docbook/xml/$(XML_VERSION4)/catalog.xml $(BUILD_STAGE)/docbook$(XML_CATALOG_FILES)
	xmlcatalog --noout --del file://$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/opt/docbook/xml/$(XML_VERSION5)/catalog.xml $(BUILD_STAGE)/docbook$(XML_CATALOG_FILES)
	xmlcatalog --noout --del file://$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/opt/docbook/xml/$(XML_VERSION6)/catalog.xml $(BUILD_STAGE)/docbook$(XML_CATALOG_FILES)
	xmlcatalog --noout --del file://$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/opt/docbook/xml/$(XML_VERSION7)/catalog.xml $(BUILD_STAGE)/docbook$(XML_CATALOG_FILES)

	xmlcatalog --noout --add nextCatalog "" file://$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/opt/docbook/xml/$(XML_VERSION0)/catalog.xml $(BUILD_STAGE)/docbook$(XML_CATALOG_FILES)
	xmlcatalog --noout --add nextCatalog "" file://$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/opt/docbook/xml/$(XML_VERSION2)/catalog.xml $(BUILD_STAGE)/docbook$(XML_CATALOG_FILES)
	xmlcatalog --noout --add nextCatalog "" file://$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/opt/docbook/xml/$(XML_VERSION3)/catalog.xml $(BUILD_STAGE)/docbook$(XML_CATALOG_FILES)
	xmlcatalog --noout --add nextCatalog "" file://$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/opt/docbook/xml/$(XML_VERSION4)/catalog.xml $(BUILD_STAGE)/docbook$(XML_CATALOG_FILES)
	xmlcatalog --noout --add nextCatalog "" file://$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/opt/docbook/xml/$(XML_VERSION5)/catalog.xml $(BUILD_STAGE)/docbook$(XML_CATALOG_FILES)
	xmlcatalog --noout --add nextCatalog "" file://$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/opt/docbook/xml/$(XML_VERSION6)/catalog.xml $(BUILD_STAGE)/docbook$(XML_CATALOG_FILES)
	xmlcatalog --noout --add nextCatalog "" file://$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/opt/docbook/xml/$(XML_VERSION7)/catalog.xml $(BUILD_STAGE)/docbook$(XML_CATALOG_FILES)

	touch $(BUILD_WORK)/docbook/.build_complete
endif

docbook-package: docbook-stage
	# docbook.mk Package Structure
	rm -rf $(BUILD_DIST)/docbook

	# docbook.mk Prep docbook
	cp -a $(BUILD_STAGE)/docbook $(BUILD_DIST)

	# docbook.mk Make .debs
	$(call PACK,docbook,DEB_DOCBOOK_V)

	# docbook.mk Build cleanup
	rm -rf $(BUILD_DIST)/docbook

.PHONY: docbook docbook-package
