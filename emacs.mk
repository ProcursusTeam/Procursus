ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUPROJECTS     += emacs
EMACS_VERSION  := 27.2
DEB_EMACS_V    ?= $(EMACS_VERSION)

emacs-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://ftpmirror.gnu.org/gnu/emacs/emacs-$(EMACS_VERSION).tar.gz{,.sig}
	$(call PGP_VERIFY,emacs-$(EMACS_VERSION).tar.gz)
	$(call EXTRACT_TAR,emacs-$(EMACS_VERSION).tar.gz,emacs-$(EMACS_VERSION),emacs)

ifneq ($(wildcard $(BUILD_WORK)/emacs/.build_complete),)
emacs:
	@echo "Using previously built emacs."
else
emacs: emacs-setup
	cd $(BUILD_WORK)/emacs && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS) \
		--without-ns \
		--with-gnutls=ifavailable
	+$(MAKE) -C $(BUILD_WORK)/emacs
	+$(MAKE) -C $(BUILD_WORK)/emacs install \
		DESTDIR=$(BUILD_STAGE)/emacs
	# Mark emacs as complete; prevents re-compiling
	touch $(BUILD_WORK)/emacs/.build_complete
endif

emacs-package: emacs-stage
	# emacs.mk Package Structure
	mkdir -p $(BUILD_DIST)/emacs

	# emacs.mk Prep emacs
	cp -a $(BUILD_STAGE)/emacs $(BUILD_DIST)

	# emacs.mk Sign
	$(call SIGN,emacs,general.xml)

	# emacs.mk Make .debs
	$(call PACK,emacs,DEB_EMACS_V)

	# emacs.mk Build cleanup
	rm -rf $(BUILD_DIST)/emacs

.PHONY: emacs emacs-package
