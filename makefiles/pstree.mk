ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += pstree
PSTREE_VERSION := 2.39
DEB_PSTREE_V   ?= $(PSTREE_VERSION)

pstree-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://fossies.org/linux/misc/pstree-$(PSTREE_VERSION).tar.gz
	mkdir -p $(BUILD_WORK)/pstree
	$(TAR) xf $(BUILD_SOURCE)/pstree-$(PSTREE_VERSION).tar.gz -C $(BUILD_WORK)/pstree

ifneq ($(wildcard $(BUILD_WORK)/pstree/.build_complete),)
pstree:
	@echo "Using previously built pstree."
else
pstree: pstree-setup
	$(MAKE) -C $(BUILD_WORK)/pstree pstree
	$(INSTALL) -Dm755 $(BUILD_WORK)/pstree/pstree \
		$(BUILD_STAGE)/pstree/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/pstree
	$(INSTALL) -Dm644 $(BUILD_WORK)/pstree/pstree.1 \
		$(BUILD_STAGE)/pstree/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/pstree.1
	touch $(BUILD_WORK)/pstree/.build_complete
endif

pstree-package: pstree-stage
	# pstree.mk Package Structure
	rm -rf $(BUILD_DIST)/pstree
	mkdir -p $(BUILD_DIST)/pstree

	# pstree.mk Prep pstree
	cp -a $(BUILD_STAGE)/pstree $(BUILD_DIST)

	# pstree.mk Sign
	$(call SIGN,pstree,general.xml)

	# pstree.mk Make .debs
	$(call PACK,pstree,DEB_PSTREE_V)

	# pstree.mk Build cleanup
	rm -rf $(BUILD_DIST)/pstree

.PHONY: pstree pstree-package
