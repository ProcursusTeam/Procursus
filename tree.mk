ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS  += tree
TREE_VERSION := 1.8.0
DEB_TREE_V   ?= $(TREE_VERSION)-1

tree-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) http://mama.indstate.edu/users/ice/tree/src/tree-$(TREE_VERSION).tgz
	$(call EXTRACT_TAR,tree-$(TREE_VERSION).tgz,tree-$(TREE_VERSION),tree)
	$(call DO_PATCH,tree,tree,-p1)

ifneq ($(wildcard $(BUILD_WORK)/tree/.build_complete),)
tree:
	@echo "Using previously built tree."
else
tree: tree-setup
	+$(MAKE) -C $(BUILD_WORK)/tree
	+$(MAKE) -C $(BUILD_WORK)/tree install \
		prefix=$(BUILD_STAGE)/tree/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	touch $(BUILD_WORK)/tree/.build_complete
endif

tree-package: tree-stage
	# tree.mk Package Structure
	rm -rf $(BUILD_DIST)/tree
	mkdir -p $(BUILD_DIST)/tree

	# tree.mk Prep tree
	cp -a $(BUILD_STAGE)/tree $(BUILD_DIST)/

	# tree.mk Sign
	$(call SIGN,tree,general.xml)

	# tree.mk Make .debs
	$(call PACK,tree,DEB_TREE_V)

	# tree.mk Build cleanup
	rm -rf $(BUILD_DIST)/tree

.PHONY: tree tree-package
