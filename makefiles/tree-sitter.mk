ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += tree-sitter
TREE_SITTER_VERSION := 0.20.8
DEB_TREE_SITTER_V   ?= $(TREE_SITTER_VERSION)

tree-sitter-setup: setup
	$(call GITHUB_ARCHIVE,tree-sitter,tree-sitter,$(TREE_SITTER_VERSION),v$(TREE_SITTER_VERSION))
	$(call EXTRACT_TAR,tree-sitter-$(TREE_SITTER_VERSION).tar.gz,tree-sitter-$(TREE_SITTER_VERSION),tree-sitter)
	sed -i s/'$$(shell uname)'/'Darwin'/ $(BUILD_WORK)/tree-sitter/Makefile

ifneq ($(wildcard $(BUILD_WORK)/tree-sitter/.build_complete),)
tree-sitter:
	@echo "Using previously built tree-sitter."
else
tree-sitter: tree-sitter-setup
	+$(MAKE) -C $(BUILD_WORK)/tree-sitter \
		PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"
	+$(MAKE) -C $(BUILD_WORK)/tree-sitter install \
		PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		DESTDIR="$(BUILD_STAGE)/tree-sitter"
	+$(MAKE) -C $(BUILD_WORK)/tree-sitter install \
		PREFIX="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		DESTDIR="$(BUILD_BASE)"
	$(call AFTER_BUILD,copy)
endif

tree-sitter-package: tree-sitter-stage
	# tree-sitter.mk Package Structure
	rm -rf $(BUILD_DIST)/libtree-sitter{0,-dev}
	mkdir -p $(BUILD_DIST)/libtree-sitter{0,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# tree-sitter.mk Prep libtree-sitter0
	cp -a $(BUILD_STAGE)/tree-sitter/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libtree-sitter.*.dylib $(BUILD_DIST)/libtree-sitter0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	
	# tree-sitter.mk Prep libtree-sitter-dev
	cp -a $(BUILD_STAGE)/tree-sitter/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libtree-sitter.{dylib,a},pkgconfig} $(BUILD_DIST)/libtree-sitter-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/tree-sitter/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libtree-sitter-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	
	# tree-sitter.mk Sign
	$(call SIGN,libtree-sitter0,general.xml)
	
	# tree-sitter.mk Make .debs
	$(call PACK,libtree-sitter0,DEB_TREE_SITTER_V)
	$(call PACK,libtree-sitter-dev,DEB_TREE_SITTER_V)
	
	# tree-sitter.mk Build cleanup
	rm -rf $(BUILD_DIST)/libtree-sitter{0,-dev}

.PHONY: tree-sitter tree-sitter-package
