ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

ifneq (,$(findstring darwin,$(MEMO_TARGET)))

SUBPROJECTS           += opendircolors
opendircolors_VERSION := 0.0.1
DEB_opendircolors_V   ?= $(opendircolors_VERSION)

opendircolors-setup: setup
	$(call GITHUB_ARCHIVE,CRKatri,opendircolors,$(opendircolors_VERSION),v$(opendircolors_VERSION))
	$(call EXTRACT_TAR,opendircolors-$(opendircolors_VERSION).tar.gz,opendircolors-$(opendircolors_VERSION),opendircolors)
	mkdir -p $(BUILD_STAGE)/opendircolors/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man1}

ifneq ($(wildcard $(BUILD_WORK)/opendircolors/.build_complete),)
opendircolors:
	@echo "Using previously built opendircolors."
else
opendircolors: opendircolors-setup
	$(CC) $(CFLAGS) -c -o $(BUILD_WORK)/opendircolors/common.o $(BUILD_WORK)/opendircolors/common.c
	$(CC) $(CFLAGS) -c -o $(BUILD_WORK)/opendircolors/dirconvert.o $(BUILD_WORK)/opendircolors/dirconvert.c
	$(CC) $(CFLAGS) -c -o $(BUILD_WORK)/opendircolors/opendircolors.o $(BUILD_WORK)/opendircolors/opendircolors.c
	$(CC) $(LDFLAGS) -o $(BUILD_STAGE)/opendircolors/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/opendircolors $(BUILD_WORK)/opendircolors/{opendircolors,common}.o
	$(CC) $(LDFLAGS) -o $(BUILD_STAGE)/opendircolors/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/dirconvert $(BUILD_WORK)/opendircolors/{dirconvert,common}.o
	cp -a $(BUILD_WORK)/opendircolors/*.1 $(BUILD_STAGE)/opendircolors/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/
	$(LN) -s opendircolors.1 $(BUILD_STAGE)/opendircolors/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/dircolors.1
	touch $(BUILD_WORK)/opendircolors/.build_complete
endif

opendircolors-package: opendircolors-stage
	# opendircolors.mk Package Structure
	rm -rf $(BUILD_DIST)/opendircolors
	mkdir -p $(BUILD_DIST)/opendircolors
	
	# opendircolors.mk Prep opendircolors
	cp -a $(BUILD_STAGE)/opendircolors $(BUILD_DIST)
	
	# opendircolors.mk Sign
	$(call SIGN,opendircolors,general.xml)
	
	# opendircolors.mk Make .debs
	$(call PACK,opendircolors,DEB_opendircolors_V)
	
	# opendircolors.mk Build cleanup
	rm -rf $(BUILD_DIST)/opendircolors

.PHONY: opendircolors opendircolors-package

endif #(,$(findstring darwin,$(MEMO_TARGET)))
