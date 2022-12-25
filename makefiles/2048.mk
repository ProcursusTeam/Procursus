ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += 2048
2048_VERSION  := 2022.10.23
DEB_2048_V    ?= 0.$(2048_VERSION)
2048_GIT_HASH := 6c04517bb59c28f3831585da338f021bc2ea86d6

2048-setup: setup
	$(call DOWNLOAD_FILE,$(BUILD_SOURCE)/2048-$(2048_GIT_HASH).c, \
		https://github.com/mevdschee/2048.c/raw/$(2048_GIT_HASH)/2048.c)
	mkdir -p $(BUILD_WORK)/2048 $(BUILD_STAGE)/2048/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	cp $(BUILD_SOURCE)/2048-$(2048_GIT_HASH).c $(BUILD_WORK)/2048/2048.c

ifneq ($(wildcard $(BUILD_WORK)/2048/.build_complete),)
2048:
	@echo "Using previously built 2048."
else
2048: 2048-setup
	sed -i '/#define _XOPEN_SOURCE 500/d' $(BUILD_WORK)/2048/2048.c
	cd $(BUILD_WORK)/2048 && $(CC) -std=c99 \
		$(CFLAGS) \
		2048.c \
		-o $(BUILD_WORK)/2048/2048
	$(INSTALL) -Dm755 $(BUILD_WORK)/2048/2048 $(BUILD_STAGE)/2048/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin
	$(call AFTER_BUILD)
endif

2048-package: 2048-stage
	# 2048.mk Package Structure
	rm -rf $(BUILD_DIST)/2048

	# 2048.mk Prep 2048
	cp -a $(BUILD_STAGE)/2048 $(BUILD_DIST)

	# 2048.mk Sign
	$(call SIGN,2048,general.xml)

	# 2048.mk Make .debs
	$(call PACK,2048,DEB_2048_V)

	# 2048.mk Build cleanup
	rm -rf $(BUILD_DIST)/2048

.PHONY: 2048 2048-package
