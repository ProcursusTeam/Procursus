ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += golang
GOLANG_MAJOR_V := 1.15
GOLANG_VERSION := $(GOLANG_MAJOR_V).5
DEB_GOLANG_V   ?= $(GOLANG_VERSION)

golang-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://golang.org/dl/go$(GOLANG_VERSION).src.tar.gz
	$(call EXTRACT_TAR,go$(GOLANG_VERSION).src.tar.gz,go,golang)
	mkdir -p $(BUILD_STAGE)/golang/usr/lib/go-$(GOLANG_MAJOR_V)
	mkdir -p $(BUILD_WORK)/golang/superbin
	cp -a $(BUILD_WORK)/golang/misc/ios/clangwrap.sh $(BUILD_WORK)/golang/superbin/clang

ifneq ($(ARCHES),arm64)
golang:
	@echo "Unsupported target $(MEMO_TARGET)"
else ifneq ($(UNAME),Darwin)
golang:
	@echo "golang building only supported on macOS"
else ifneq ($(wildcard $(BUILD_WORK)/golang/.build_complete),)
golang:
	@echo "Using previously built golang."
else
golang: golang-setup
	export PATH="$(BUILD_WORK)/golang/superbin:$(PATH)"; \
		cd $(BUILD_WORK)/golang/src && \
			CGO_ENABLED=1 \
			GOROOT_FINAL=/usr/lib/go-$(GOLANG_MAJOR_V) \
			GOHOSTARCH=amd64 \
			GOHOSTOS=darwin \
			GOARCH=arm64 \
			GOOS=darwin \
			CC=cc \
			CC_FOR_TARGET=clang \
			./make.bash
	cp -a $(BUILD_WORK)/golang/* $(BUILD_STAGE)/golang/usr/lib/go-$(GOLANG_MAJOR_V)
	-find $(BUILD_STAGE)/golang/usr/lib/go-$(GOLANG_MAJOR_V) -name darwin_amd64 -type d -exec rm -rf {} \;
	touch $(BUILD_WORK)/golang/.build_complete
endif

golang-package: golang-stage
	# golang.mk Package Structure
	rm -rf $(BUILD_DIST)/golang{,-$(GOLANG_MAJOR_V)}-{src,go}
	mkdir -p $(BUILD_DIST)/golang-$(GOLANG_MAJOR_V)-src/usr/lib/go-$(GOLANG_MAJOR_V) \
		$(BUILD_DIST)/golang-$(GOLANG_MAJOR_V)-go/usr/lib/go-$(GOLANG_MAJOR_V)/{bin,pkg} \
		$(BUILD_DIST)/golang-go/usr/{bin,lib}

	# golang.mk Prep golang-$(GOLANG_MAJOR_V)-src
	cp -a $(BUILD_STAGE)/golang/usr/lib/go-$(GOLANG_MAJOR_V)/{api,misc,src,test} $(BUILD_DIST)/golang-$(GOLANG_MAJOR_V)-src/usr/lib/go-$(GOLANG_MAJOR_V)
	
	# golang.mk Prep golang-$(GOLANG_MAJOR_V)-go
	cp -a $(BUILD_STAGE)/golang/usr/lib/go-$(GOLANG_MAJOR_V)/VERSION $(BUILD_DIST)/golang-$(GOLANG_MAJOR_V)-go/usr/lib/go-$(GOLANG_MAJOR_V)
	cp -a $(BUILD_STAGE)/golang/usr/lib/go-$(GOLANG_MAJOR_V)/bin/darwin_arm64/go{,fmt} $(BUILD_DIST)/golang-$(GOLANG_MAJOR_V)-go/usr/lib/go-$(GOLANG_MAJOR_V)/bin
	cp -a $(BUILD_STAGE)/golang/usr/lib/go-$(GOLANG_MAJOR_V)/pkg/{*_*,include,tool} $(BUILD_DIST)/golang-$(GOLANG_MAJOR_V)-go/usr/lib/go-$(GOLANG_MAJOR_V)/pkg
	
	# golang.mk Prep golang-go
	ln -s ../lib/go-$(GOLANG_MAJOR_V)/bin/go $(BUILD_DIST)/golang-go/usr/bin/go
	ln -s ../lib/go-$(GOLANG_MAJOR_V)/bin/gofmt $(BUILD_DIST)/golang-go/usr/bin/gofmt
	ln -s ../lib/go-$(GOLANG_MAJOR_V) $(BUILD_DIST)/golang-go/usr/lib/go

	# golang.mk Sign
	$(call SIGN,golang-$(GOLANG_MAJOR_V)-go,general.xml)
	
	# golang.mk Make .debs
	$(call PACK,golang-$(GOLANG_MAJOR_V)-src,DEB_GOLANG_V)
	$(call PACK,golang-$(GOLANG_MAJOR_V)-go,DEB_GOLANG_V)
	$(call PACK,golang-go,DEB_GOLANG_V)
	
	# golang.mk Build cleanup
	rm -rf $(BUILD_DIST)/golang{,-$(GOLANG_MAJOR_V)}-{src,go}

.PHONY: golang golang-package
