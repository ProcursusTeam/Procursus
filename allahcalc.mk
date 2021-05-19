ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += allahcalc
ALLAHCALC_VERSION := 1.1
DEB_ALLAHCALC_V   ?= $(ALLAHCALC_VERSION)

allahcalc-setup: setup
	wget -q -nc -P (BUILD_SOURCE) https://github.com/clyde37/allah-calculator/releases/download/$(ALLAHCALC_VERSION)/allah_calculator_generator.cpp

ifneq ($(wildcard $(BUILD_WORK)/allahcalc/.build_complete),)
allahcalc:
	@echo "Using previously built allahcalc."
else
allahcalc: allahcalc-setup
    clang++ allah_calculator_generator.cpp -o allahcalc/allah_calculator_generator
    ./allah_calculator_generator
    gcc allah_calculator_final.mp4_custom.c -o allahcalc/allahcalc
endif

allahcalc-package: allahcalc-stage
    $(call PACK,allahcalc,DEB_ALLAHCALC_V)
    rm -rf allahcalc

.PHONY: allahcalc allahcalc-package
