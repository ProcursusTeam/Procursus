ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS             += git-filter-repo
GIT_FILTER_REPO_VERSION := 2.29.0
DEB_GIT_FILTER_REPO_V   ?= $(GIT_FILTER_REPO_VERSION)

git-filter-repo-setup: setup
	-[ ! -f "$(BUILD_SOURCE)/git-filter-repo-$(GIT_FILTER_REPO_VERSION).tar.gz" ] && \
		wget -q -nc -O$(BUILD_SOURCE)/git-filter-repo-$(GIT_FILTER_REPO_VERSION).tar.gz \
			https://github.com/newren/git-filter-repo/releases/download/v$(GIT_FILTER_REPO_VERSION)/git-filter-repo-$(GIT_FILTER_REPO_VERSION).tar.xz
	$(call EXTRACT_TAR,git-filter-repo-$(GIT_FILTER_REPO_VERSION).tar.gz,git-filter-repo-$(GIT_FILTER_REPO_VERSION),git-filter-repo)
	$(call DO_PATCH,git-filter-repo,git-filter-repo,-p1)
	$(SED) -i 's/@PKGVER@/$(GIT_FILTER_REPO_VERSION)/g' $(BUILD_WORK)/git-filter-repo/release/setup.py

ifneq ($(wildcard $(BUILD_WORK)/git-filter-repo/.build_complete),)
git-filter-repo:
	@echo "Using previously built git-filter-repo."
else
git-filter-repo: git-filter-repo-setup
	cd $(BUILD_WORK)/git-filter-repo/release && unset MACOSX_DEPLOYMENT_TARGET && python$(PYTHON3_MAJOR_V) ./setup.py \
		install \
		--prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		--root="$(BUILD_STAGE)/git-filter-repo" \
		--install-layout=deb
	rm -rf $(BUILD_STAGE)/git-filter-repo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/python3/dist-packages/__pycache__
	$(GINSTALL) -Dm644 $(BUILD_WORK)/git-filter-repo/Documentation/man1/git-filter-repo.1 \
		$(BUILD_STAGE)/git-filter-repo/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/git-filter-repo.1
	touch $(BUILD_WORK)/git-filter-repo/.build_complete
endif
git-filter-repo-package: git-filter-repo-stage
	# git-filter-repo.mk Package Structure
	rm -rf $(BUILD_DIST)/git-filter-repo
	
	# git-filter-repo.mk Prep git-filter-repo
	cp -a $(BUILD_STAGE)/git-filter-repo $(BUILD_DIST)/
	
	#git-filter-repo.mk Make .debs
	$(call PACK,git-filter-repo,DEB_GIT_FILTER_REPO_V)
	
	# git-filter-repo.mk Build cleanup
	rm -rf $(BUILD_DIST)/git-filter-repo

.PHONY: git-filter-repo git-filter-repo-package
