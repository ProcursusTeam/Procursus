ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += bottom-rs
BOTTOM-RS_COMMIT  := 3451cdadd7c4e64fe8e7f43e986a18628a741dec
BOTTOM-RS_VERSION := 1.2.0
DEB_BOTTOM-RS_V   := $(BOTTOM-RS_VERSION)

bottom-rs-setup: setup
	$(call GITHUB_ARCHIVE,bottom-software-foundation,bottom-rs,$(BOTTOM-RS_COMMIT),$(BOTTOM-RS_COMMIT))
	$(call EXTRACT_TAR,bottom-$(BOTTOM-RS_COMMIT).tar.gz,bottom-$(BOTTOM-RS_COMMIT),bottom-rs)

ifneq ($(wildcard $(BUILD_WORK)/bottom-rs/.build_complete),)
bottom-rs:
	@echo "Using previously built bottom-rs."
else
bottom-rs: bottom-rs-setup
	cd $(BUILD_WORK)/bottom-rs/ && cargo install \
	--target $(RUST_TARGET) \
	--root $(BUILD_STAGE)/bottom-rs$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/ \
	--path .

	touch $(BUILD_WORK)/bottom-rs/.build_complete
endif

bottom-rs-package: bottom-rs-stage
	# bottom-rs.mk Package Structure
	rm -rf $(BUILD_DIST)/bottom-rs
	mkdir -p $(BUILD_DIST)//bottom-rs$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/

	# bottom-rs.mk Prep bottom-rs
	cp -a $(BUILD_STAGE)//bottom-rs$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/* $(BUILD_DIST)/bottom-rs$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/

	# bottom-rs.mk Sign
	$(call SIGN,bottom-rs,general.xml)

	# bottom-rs.mk Make .debs
	$(call PACK,bottom-rs,DEB_BOTTOM-RS_V)

	# bottom-rs.mk Build cleanup
	rm -rf $(BUILD_DIST)/bottom-rs

.PHONY: bottom-rs bottom-rs-package
