ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += allahcalc
ALLAHCALC_VERSION := 1.2
DEB_ALLAHCALC_V   ?= $(ALLAHCALC_VERSION)

allahcalc-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://github.com/clyde37/allah-calculator/archive/refs/tags/$(ALLAHCALC_VERSION).tar.gz
	$(call EXTRACT_TAR,allah-calculator-$(ALLAHCALC_VERSION).tar.gz,allah-calculator-$(ALLAHCALC_VERSION),allahcalc)

ifneq ($(wildcard $(BUILD_WORK)/allahcalc/.build_complete),)
allahcalc:
	@echo "Using previously built allahcalc."
else
allahcalc: allahcalc-setup
	cd $(BUILD_WORK)/allahcalc
	$(CC)++ allah_calculator_generator.cpp -o allahcalc/allah_calculator_generator
	./allah_calculator_generator
	$(CC) allah_calculator_final.mp4_custom.c \
		-o $(BUILD_STAGE)/allahcalc
endif

allahcalc-package: allahcalc-stage
	rm -rf $(BUILD_DIST)/allahcalc
	cp -a $(BUILD_STAGE)/allahcalc $(BUILD_DIST)
	$(call SIGN,allahcalc)
	$(call PACK,allahcalc,DEB_ALLAHCALC_V)
	rm -rf $(BUILD_DIST)/allahcalc

.PHONY: allahcalc allahcalc-package
