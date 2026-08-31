ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS           += golang
GOLANG_MAJOR_V        := 1.22
GOLANG_VERSION        := $(GOLANG_MAJOR_V).4
DEBIAN_GOLANG_VERSION := 1.22~3
DEB_GOLANG_V          ?= $(GOLANG_VERSION)

golang-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://go.dev/dl/go$(GOLANG_VERSION).src.tar.gz)
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://deb.debian.org/debian/pool/main/g/golang-defaults/golang-defaults_$(DEBIAN_GOLANG_VERSION).tar.xz)
	$(call EXTRACT_TAR,go$(GOLANG_VERSION).src.tar.gz,go,golang)
	$(call EXTRACT_TAR,golang-defaults_$(DEBIAN_GOLANG_VERSION).tar.xz,golang-defaults-$(DEBIAN_GOLANG_VERSION),golang/debian)
	if [ ! -f $(BUILD_WORK)/golang/src/syscall/zsyscall_ios_arm64.go ]; then \
		cd $(BUILD_WORK)/golang/src/syscall; ./mksyscall.pl -darwin -tags ios,arm64 syscall_bsd.go syscall_darwin.go syscall_darwin_arm64.go >\
			$(BUILD_WORK)/golang/src/syscall/zsyscall_ios_arm64.go; \
	fi
	$(call DO_PATCH,golang,golang,-p1)
	mkdir -p $(BUILD_STAGE)/golang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{share/man/man{1,7},lib/go-$(GOLANG_MAJOR_V)}
	mkdir -p $(BUILD_WORK)/golang/superbin
	echo -e "#!/bin/sh\nexec $$(which $(CC)) $(shell echo $(CFLAGS) | sed 's/$(OPTIMIZATION_FLAGS)//') \"\$$@\"" > $(BUILD_WORK)/golang/superbin/cc
	echo -e "#!/bin/sh\nexec $(CC_FOR_BUILD) \"\$$@\"" > $(BUILD_WORK)/golang/superbin/clang
	chmod 0755 $(BUILD_WORK)/golang/superbin/{cc,clang}


ifneq ($(wildcard $(BUILD_WORK)/golang/.build_complete),)
golang:
	@echo "Using previously built golang."
else
golang: golang-setup
	export PATH="$(BUILD_WORK)/golang/superbin:$(PATH)"; \
	cd $(BUILD_WORK)/golang/src && \
		CGO_ENABLED=1 \
		GOROOT_FINAL=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V) \
		GOOS=$(GOLANG_OS) \
		GOARCH=$(shell echo $(MEMO_TARGET) | cut -f2 -d-) \
		CC="clang" \
		CC_FOR_TARGET="cc" \
		CXX_FOR_TARGET="c++" \
		CGO_CFLAGS="-Os" \
		CGO_CXXFLAGS="-Os" \
		CGO_FFLAGS="-Os" \
		CGO_LDFLAGS="-Os -L$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib" \
		./make.bash
	GOTARGET="$(GOLANG_OS)_$(shell echo $(MEMO_TARGET) | cut -f2 -d-)"; \
	cd $(BUILD_WORK)/golang/pkg/tool/; \
	for i in *; do \
		if [ "$$i" != "$$GOTARGET" ]; then \
			rm -r "$$i"; \
		fi; \
	done; \
	if [ -d "$(BUILD_WORK)/golang/bin/$${GOTARGET}" ]; then \
		cp -a $(BUILD_WORK)/golang/bin/$${GOTARGET}/go{,fmt} $(BUILD_WORK)/golang/bin; \
		rm -r $(BUILD_WORK)/golang/bin/$${GOTARGET}; \
	fi
	find $(BUILD_WORK)/golang/pkg -type d -empty -delete
	# Setup golang-go
	mkdir -p $(BUILD_STAGE)/golang/go/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/ \
		$(BUILD_STAGE)/golang/go/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,share/man/man{1,7}}
	cp -a $(BUILD_WORK)/golang/debian/man/*.1 $(BUILD_STAGE)/golang/go/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man1/
	cp -a $(BUILD_WORK)/golang/debian/man/*.7 $(BUILD_STAGE)/golang/go/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man/man7/
	$(LN_S) go-$(GOLANG_MAJOR_V) $(BUILD_STAGE)/golang/go/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go
	$(LN_S) ../lib/go-$(GOLANG_MAJOR_V)/bin/go $(BUILD_STAGE)/golang/go/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/go
	$(LN_S) ../lib/go-$(GOLANG_MAJOR_V)/bin/gofmt $(BUILD_STAGE)/golang/go/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/gofmt
	# Setup golang-X.Y-go
	mkdir -p $(BUILD_STAGE)/golang/go-v/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,share}/go-$(GOLANG_MAJOR_V)/pkg
	cp -a $(BUILD_WORK)/golang/{VERSION,bin,go.env} $(BUILD_STAGE)/golang/go-v/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)/
	cp -a $(BUILD_WORK)/golang/pkg/tool $(BUILD_STAGE)/golang/go-v/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)/pkg
	cp -a $(BUILD_WORK)/golang/pkg/include $(BUILD_STAGE)/golang/go-v/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/go-$(GOLANG_MAJOR_V)/pkg
	$(LN_S) ../../../share/go-$(GOLANG_MAJOR_V)/pkg/include $(BUILD_STAGE)/golang/go-v/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)/pkg/include
	for i in api misc src test; do \
		$(LN_S) ../../share/go-$(GOLANG_MAJOR_V)/$$i $(BUILD_STAGE)/golang/go-v/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)/$$i; \
	done
	# Setup golang-X.Y-src
	mkdir -p $(BUILD_STAGE)/golang/src/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/go-$(GOLANG_MAJOR_V)
	cp -a $(BUILD_WORK)/golang/{api,misc,src,test} $(BUILD_STAGE)/golang/src/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/go-$(GOLANG_MAJOR_V)/
	# Generated files
	GENERATED_FILES="src/cmd/go/internal/cfg/zdefaultcc.go src/go/build/zcgo.go src/runtime/internal/sys/zversion.go src/time/tzdata/zzipdata.go src/cmd/cgo/zdefaultcc.go src/cmd/internal/objabi/zbootstrap.go src/internal/buildcfg/zbootstrap.go"; \
	cd $(BUILD_WORK)/golang; \
	cp --parent -v $$GENERATED_FILES $(BUILD_STAGE)/golang/go-v/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/go-$(GOLANG_MAJOR_V); \
	cd $(BUILD_STAGE)/golang/src/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/go-$(GOLANG_MAJOR_V); \
	rm -v -f $$GENERATED_FILES
	$(call AFTER_BUILD)
endif

golang-package: golang-stage
	# golang.mk Package Structure
	rm -rf $(BUILD_DIST)/golang{,-$(GOLANG_MAJOR_V)}-{src,go}
	mkdir -p $(BUILD_DIST)/golang{,-$(GOLANG_MAJOR_V)} \
		$(BUILD_DIST)/golang-src/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share

	# golang.mk Prep golang-$(GOLANG_MAJOR_V)-src
	cp -a $(BUILD_STAGE)/golang/src $(BUILD_DIST)/golang-$(GOLANG_MAJOR_V)-src

	# golang.mk Prep golang-$(GOLANG_MAJOR_V)-go
	cp -a $(BUILD_STAGE)/golang/go-v $(BUILD_DIST)/golang-$(GOLANG_MAJOR_V)-go

	# golang.mk Prep golang-go
	cp -a $(BUILD_STAGE)/golang/go $(BUILD_DIST)/golang-go

	# golang.mk Prep golang-src
	$(LN_S) go-$(GOLANG_MAJOR_V) $(BUILD_DIST)/golang-src/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/go

	# golang.mk Sign
	$(call SIGN,golang-$(GOLANG_MAJOR_V)-go,general.xml)

	# golang.mk Make .debs
	$(call PACK,golang-$(GOLANG_MAJOR_V)-src,DEB_GOLANG_V)
	$(call PACK,golang-$(GOLANG_MAJOR_V)-go,DEB_GOLANG_V)
	$(call PACK,golang-$(GOLANG_MAJOR_V),DEB_GOLANG_V)
	$(call PACK,golang,DEB_GOLANG_V)
	$(call PACK,golang-go,DEB_GOLANG_V)
	$(call PACK,golang-src,DEB_GOLANG_V)

	# golang.mk Build cleanup
	rm -rf $(BUILD_DIST)/golang{,-$(GOLANG_MAJOR_V)}{,-src,-go}

.PHONY: golang golang-package
