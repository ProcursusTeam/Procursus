ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS             += ondeviceconsole
ONDEVICECONSOLE_VERSION := 1.0.1
ONDEVICECONSOLE_COMMIT  := 4ecffbaa1bfce7f250e99205697523194193388f
DEB_ONDEVICECONSOLE_V   ?= $(ONDEVICECONSOLE_VERSION)

ondeviceconsole-setup: setup
	mkdir -p $(BUILD_WORK)/ondeviceconsole
	wget -q -nc -P $(BUILD_WORK)/ondeviceconsole \
		https://raw.githubusercontent.com/eswick/ondeviceconsole/$(ONDEVICECONSOLE_COMMIT)/main.m
	$(SED) -i '\|#import <sys/socket.h>|a #import <Foundation/Foundation.h>' \
		$(BUILD_WORK)/ondeviceconsole/main.m
	mkdir -p $(BUILD_STAGE)/ondeviceconsole/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin

ifneq ($(wildcard $(BUILD_WORK)/ondeviceconsole/.build_complete),)
ondeviceconsole:
	@echo "Using previously built ondeviceconsole."
else
ondeviceconsole: ondeviceconsole-setup
	$(CC) $(CFLAGS) $(BUILD_WORK)/ondeviceconsole/main.m -framework Foundation \
		-o $(BUILD_STAGE)/ondeviceconsole/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/ondeviceconsole
	touch $(BUILD_WORK)/ondeviceconsole/.build_complete
endif

ondeviceconsole-package: ondeviceconsole-stage
	# ondeviceconsole.mk Package Structure
	rm -rf $(BUILD_DIST)/ondeviceconsole
	mkdir -p $(BUILD_DIST)/ondeviceconsole

	# ondeviceconsole.mk Prep ondeviceconsole
	cp -a $(BUILD_STAGE)/ondeviceconsole $(BUILD_DIST)

	# ondeviceconsole.mk Sign
	$(call SIGN,ondeviceconsole,general.xml)

	# ondeviceconsole.mk Make .debs
	$(call PACK,ondeviceconsole,DEB_ONDEVICECONSOLE_V)

	# ondeviceconsole.mk Build cleanup
	rm -rf $(BUILD_DIST)/ondeviceconsole

.PHONY: ondeviceconsole ondeviceconsole-package
