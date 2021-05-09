ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif
SUBPROJECTS    += golang
GOLANG_MAJOR_V := 1.16
GOLANG_VERSION := $(GOLANG_MAJOR_V).3
DEB_GOLANG_V   ?= $(GOLANG_VERSION)-1

golang-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://golang.org/dl/go$(GOLANG_VERSION).src.tar.gz
	$(call EXTRACT_TAR,go$(GOLANG_VERSION).src.tar.gz,go,golang)
	mkdir -p $(BUILD_STAGE)/golang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)
	mkdir -p $(BUILD_WORK)/golang/superbin
ifneq (,$(findstring ios,$(shell echo $(RUST_TARGET) | cut -f3 -d-)))
	cp -a $(BUILD_WORK)/golang/misc/ios/clangwrap.sh $(BUILD_WORK)/golang/superbin/$(CC)
endif

ifneq ($(wildcard $(BUILD_WORK)/golang/.build_complete),)
golang:
	@echo "Using previously built golang."
else
golang: golang-setup
	export PATH="$(BUILD_WORK)/golang/superbin:$(PATH)"; \
	cd $(BUILD_WORK)/golang/src && \
		CGO_ENABLED=1 \
		GOROOT_FINAL=$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V) \
		GOOS=$(shell echo $(RUST_TARGET) | cut -f3 -d-) \
		GOARCH=$(shell echo $(MEMO_TARGET) | cut -f2 -d-) \
		CC=$(shell which cc) \
		CC_FOR_TARGET="$(CC)" \
		./make.bash
	cp -a $(BUILD_WORK)/golang/* $(BUILD_STAGE)/golang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)
ifneq (,$(findstring arm64,$(MEMO_TARGET)))
	-find $(BUILD_STAGE)/golang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V) -name darwin_amd64 -type d -exec rm -rf {} \;
else
	-find $(BUILD_STAGE)/golang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V) -name darwin_arm64 -type d -exec rm -rf {} \;
endif
	if [ -d "$(BUILD_STAGE)/golang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)/bin/$(shell echo $(RUST_TARGET) | cut -f3 -d-)_$(shell echo $(MEMO_TARGET) | cut -f2 -d-)" ]; then \
		cp -a $(BUILD_STAGE)/golang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)/bin/$(shell echo $(RUST_TARGET) | cut -f3 -d-)_$(shell echo $(MEMO_TARGET) | cut -f2 -d-)/go{,fmt} $(BUILD_STAGE)/golang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)/bin; \
	fi
	touch $(BUILD_WORK)/golang/.build_complete
endif

golang-package: golang-stage
	# golang.mk Package Structure
	rm -rf $(BUILD_DIST)/golang{,-$(GOLANG_MAJOR_V)}-{src,go}
	mkdir -p $(BUILD_DIST)/golang-$(GOLANG_MAJOR_V)-src/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V) \
		$(BUILD_DIST)/golang-$(GOLANG_MAJOR_V)-go/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)/{bin,pkg} \
		$(BUILD_DIST)/golang-go/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{bin,lib}
	# golang.mk Prep golang-$(GOLANG_MAJOR_V)-src
	cp -a $(BUILD_STAGE)/golang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)/{api,misc,src,test} $(BUILD_DIST)/golang-$(GOLANG_MAJOR_V)-src/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)

	# golang.mk Prep golang-$(GOLANG_MAJOR_V)-go
	cp -a $(BUILD_STAGE)/golang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)/VERSION $(BUILD_DIST)/golang-$(GOLANG_MAJOR_V)-go/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)
	cp -a $(BUILD_STAGE)/golang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)/bin/go{,fmt} $(BUILD_DIST)/golang-$(GOLANG_MAJOR_V)-go/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)/bin
	cp -a $(BUILD_STAGE)/golang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)/pkg/{*_*,include,tool} $(BUILD_DIST)/golang-$(GOLANG_MAJOR_V)-go/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)/pkg

	# golang.mk Prep golang-go
	ln -s ../lib/go-$(GOLANG_MAJOR_V)/bin/go $(BUILD_DIST)/golang-go/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/go
	ln -s ../lib/go-$(GOLANG_MAJOR_V)/bin/gofmt $(BUILD_DIST)/golang-go/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin/gofmt
	ln -s ../lib/go-$(GOLANG_MAJOR_V) $(BUILD_DIST)/golang-go/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go
	# golang.mk Sign
	$(call SIGN,golang-$(GOLANG_MAJOR_V)-go,general.xml)

	# golang.mk Make .debs
	$(call PACK,golang-$(GOLANG_MAJOR_V)-src,DEB_GOLANG_V)
	$(call PACK,golang-$(GOLANG_MAJOR_V)-go,DEB_GOLANG_V)
	$(call PACK,golang-go,DEB_GOLANG_V)

	# golang.mk Build cleanup
	rm -rf $(BUILD_DIST)/golang{,-$(GOLANG_MAJOR_V)}-{src,go}
.PHONY: golang golang-package
