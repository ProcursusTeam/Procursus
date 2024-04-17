ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifeq (,$(findstring darwin,$(MEMO_TARGET)))
STRAPPROJECTS += grep
else # ($(MEMO_TARGET),darwin-\*)
SUBPROJECTS   += grep
endif # ($(MEMO_TARGET),darwin-\*)
GREP_VERSION  := 3.11
DEB_GREP_V    ?= $(GREP_VERSION)

grep-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://ftpmirror.gnu.org/grep/grep-$(GREP_VERSION).tar.xz{$(comma).sig})
	$(call PGP_VERIFY,grep-$(GREP_VERSION).tar.xz)
	$(call EXTRACT_TAR,grep-$(GREP_VERSION).tar.xz,grep-$(GREP_VERSION),grep)

ifneq ($(wildcard $(BUILD_WORK)/grep/.build_complete),)
grep:
	@echo "Using previously built grep."
else
ifeq (,$(findstring ramdisk,$(MEMO_TARGET)))
grep: grep-setup pcre2
else
grep: grep-setup
endif
	cd $(BUILD_WORK)/grep && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--with-packager="$(DEB_MAINTAINER)" \
		--program-prefix="$(GNU_PREFIX)"
	+$(MAKE) -C $(BUILD_WORK)/grep
	+$(MAKE) -C $(BUILD_WORK)/grep install \
		DESTDIR="$(BUILD_STAGE)/grep"
	$(call AFTER_BUILD)
endif

grep-package: grep-stage
	# grep.mk Package Structure
	rm -rf $(BUILD_DIST)/grep
	mkdir -p $(BUILD_DIST)/grep/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# grep.mk Prep grep
	cp -a $(BUILD_STAGE)/grep/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share} $(BUILD_DIST)/grep/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

ifneq (,$(findstring darwin,$(MEMO_TARGET)))
	mkdir -p $(BUILD_DIST)/grep/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/gnubin
	for bin in $(BUILD_DIST)/grep/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/*; do \
		$(LN_S) $(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/$${bin##*/} $(BUILD_DIST)/grep/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/libexec/gnubin/$$(echo $${bin##*/} | cut -c2-); \
	done
endif

	# grep.mk Sign
	$(call SIGN,grep,general.xml)

	# grep.mk Make .debs
	$(call PACK,grep,DEB_GREP_V)

	# grep.mk Build cleanup
	rm -rf $(BUILD_DIST)/grep

.PHONY: grep grep-package
