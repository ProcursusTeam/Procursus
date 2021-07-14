ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += asciidoctor
ASCIIDOCTOR_VERSION := 2.0.15
DEB_ASCIIDOCTOR_V   ?= $(ASCIIDOCTOR_VERSION)

asciidoctor-setup: setup
	wget -q -nc -P $(BUILD_SOURCE)/gems https://rubygems.org/downloads/asciidoctor-$(ASCIIDOCTOR_VERSION).gem
ifneq ($(wildcard $(BUILD_WORK)/asciidoctor/.build_complete),)
asciidoctor:
	@echo "Using previously built asciidoctor."
else
asciidoctor: asciidoctor-setup
	mkdir -p $(BUILD_WORK)/asciidoctor
	gem3.0 install \
			--ignore-dependencies \
			--no-user-install \
			--verbose \
			-i $(BUILD_STAGE)/asciidoctor/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/ruby/gems/3.0.0 \
			-n $(BUILD_STAGE)/asciidoctor/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin \
			--local \
			$(BUILD_SOURCE)/gems/asciidoctor-$(ASCIIDOCTOR_VERSION).gem
	touch $(BUILD_WORK)/asciidoctor/.build_complete
endif

asciidoctor-package: asciidoctor-stage
	# asciidoctor.mk Package Structure
	rm -rf $(BUILD_DIST)/asciidoctor{,-doc}

	# asciidoctor.mk Prep asciidoctor
	cp -a $(BUILD_STAGE)/asciidoctor $(BUILD_DIST)
	mkdir -p $(BUILD_DIST)/asciidoctor-doc/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/lib/ruby/gems/3.0.0/
	mv $(BUILD_DIST)/asciidoctor/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/ruby/gems/3.0.0/doc \
			$(BUILD_DIST)/asciidoctor-doc/$(MEMO_PREFIX)/$(MEMO_SUB_PREFIX)/lib/ruby/gems/3.0.0/doc

	# asciidoctor.mk Make .debs
	$(call PACK,asciidoctor,DEB_ASCIIDOCTOR_V)
	$(call PACK,asciidoctor-doc,DEB_ASCIIDOCTOR_V)

	# asciidoctor.mk Build cleanup
	rm -rf $(BUILD_DIST)/asciidoctor{,-doc}

.PHONY: asciidoctor asciidoctor-package
