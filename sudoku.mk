ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS     += sudoku
SUDOKU_VERSION  := 1.0.5
DEB_SUDOKU_V    ?= $(SUDOKU_VERSION)

sudoku-setup: setup
	$(call GITHUB_ARCHIVE,cinemast,sudoku,$(SUDOKU_VERSION),v$(SUDOKU_VERSION))
	$(call EXTRACT_TAR,sudoku-$(SUDOKU_VERSION).tar.gz,sudoku-$(SUDOKU_VERSION),sudoku)
	$(call DO_PATCH,sudoku,sudoku,-p1)

ifneq ($(wildcard $(BUILD_WORK)/sudoku/.build_complete),)
sudoku:
	@echo "Using previously built sudoku."
else
sudoku: sudoku-setup ncurses
	$(MAKE) -C $(BUILD_WORK)/sudoku
	$(MAKE) -C $(BUILD_WORK)/sudoku install \
		DESTDIR=$(BUILD_STAGE)/sudoku \
		PREFIX=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)
	touch $(BUILD_WORK)/sudoku/.build_complete
endif

sudoku-package: sudoku-stage
	# sudoku.mk Package Structure
	rm -rf $(BUILD_DIST)/sudoku
	mkdir -p $(BUILD_DIST)/sudoku

	# sudoku.mk Prep sudoku
	cp -a $(BUILD_STAGE)/sudoku/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) $(BUILD_DIST)/sudoku

	# sudoku.mk Sign
	$(call SIGN,sudoku,general.xml)

	# sudoku.mk Make .debs
	$(call PACK,sudoku,DEB_SUDOKU_V)

	# sudoku.mk Build cleanup
	rm -rf $(BUILD_DIST)/sudoku

.PHONY: sudoku sudoku-package
