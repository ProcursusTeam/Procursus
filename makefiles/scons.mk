ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += scons
SCONS_VERSION := 4.3.0
DEB_SCONS_V   ?= $(SCONS_VERSION)

scons-setup: setup
	wget -q -nc -P$(BUILD_SOURCE) https://files.pythonhosted.org/packages/64/a1/9dc5c5e43b3d1b1832da34c8ae7b239a8f2847c33509fa0eb011fd8bc1ad/SCons-$(SCONS_VERSION).tar.gz
	$(call EXTRACT_TAR,SCons-$(SCONS_VERSION).tar.gz,SCons-$(SCONS_VERSION),scons)
	$(call DO_PATCH,scons,scons,-p1)

ifneq ($(wildcard $(BUILD_WORK)/scons/.build_complete),)
scons:
	@echo "Using previously built scons."
else
scons: scons-setup python3
	cd $(BUILD_WORK)/scons && $(DEFAULT_SETUP_PY_ENV) python3 ./setup.py \
		build \
		--executable="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/python3" \
		install \
		--install-layout=deb \
		--root="$(BUILD_STAGE)/scons" \
		--prefix="$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)"
	find $(BUILD_STAGE)/scons -name __pycache__ -prune -exec rm -rf {} \;
	mkdir -p $(BUILD_STAGE)/scons/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	mv $(BUILD_STAGE)/scons/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/*.1 $(BUILD_STAGE)/scons/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1
	$(call AFTER_BUILD)
endif

scons-package: scons-stage
	# scons.mk Package Structure
	rm -rf $(BUILD_DIST)/scons

	# scons.mk Prep scons
	cp -a $(BUILD_STAGE)/scons $(BUILD_DIST)

	#scons.mk Make .debs
	$(call PACK,scons,DEB_SCONS_V)

	# scons.mk Build cleanup
	rm -rf $(BUILD_DIST)/scons

.PHONY: scons scons-package
