ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS += jo
JO_VERSION  := 1.6
DEB_JO_V    ?= $(JO_VERSION)

jo-setup: setup
	$(call GITHUB_ARCHIVE,jpmens,jo,$(JO_VERSION),$(JO_VERSION))
	$(call EXTRACT_TAR,jo-$(JO_VERSION).tar.gz,jo-$(JO_VERSION),jo)

ifneq ($(wildcard $(BUILD_WORK)/jo/.build_complete),)
jo:
	@echo "Using previously built jo."
else
jo: jo-setup
	cd $(BUILD_WORK)/jo && autoreconf -fi
	cd $(BUILD_WORK)/jo && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/jo
	+$(MAKE) -C $(BUILD_WORK)/jo install \
		DESTDIR=$(BUILD_STAGE)/jo
	$(call AFTER_BUILD)
endif

jo-package: jo-stage
	# jo.mk Package Structure
	rm -rf $(BUILD_DIST)/jo

	# jo.mk Prep jo
	cp -a $(BUILD_STAGE)/jo $(BUILD_DIST)

	# jo.mk Sign
	$(call SIGN,jo,general.xml)

	# jo.mk Make .debs
	$(call PACK,jo,DEB_JO_V)

	# jo.mk Build cleanup
	rm -rf $(BUILD_DIST)/jo

.PHONY: jo jo-package
