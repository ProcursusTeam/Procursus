ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS    += golang
GOLANG_MAJOR_V := 1.16
GOLANG_VERSION := $(GOLANG_MAJOR_V).5
DEB_GOLANG_V   ?= $(GOLANG_VERSION)

golang-setup: setup
	wget -q -nc -P $(BUILD_SOURCE) https://golang.org/dl/go$(GOLANG_VERSION).src.tar.gz
	$(call EXTRACT_TAR,go$(GOLANG_VERSION).src.tar.gz,go,golang)
	$(call DO_PATCH,golang,golang,-p1)
	mkdir -p $(BUILD_STAGE)/golang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)
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
		GOOS=$(shell echo $(RUST_TARGET) | cut -f3 -d-) \
		GOARCH=$(shell echo $(MEMO_TARGET) | cut -f2 -d-) \
		CC="clang" \
		CC_FOR_TARGET="cc" \
		CXX_FOR_TARGET="c++" \
		CGO_CFLAGS="-Os" \
		CGO_CXXFLAGS="-Os" \
		CGO_FFLAGS="-Os" \
		CGO_LDFLAGS="-Os -L$(BUILD_BASE)/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib" \
		./make.bash
	cp -a $(BUILD_WORK)/golang/* $(BUILD_STAGE)/golang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)
	VAR=$$(ls $(BUILD_STAGE)/golang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)/pkg/tool | grep -v $(shell echo $(RUST_TARGET) | cut -f3 -d-)_$(shell echo $(MEMO_TARGET) | cut -f2 -d-)); \
	if [ ! -z "$$VAR" ]; then \
		find $(BUILD_STAGE)/golang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V) -name $$VAR -type d -prune -exec rm -rf {} \; ; \
	fi
	if [ -d "$(BUILD_STAGE)/golang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)/bin/$(shell echo $(RUST_TARGET) | cut -f3 -d-)_$(shell echo $(MEMO_TARGET) | cut -f2 -d-)" ]; then \
		cp -a $(BUILD_STAGE)/golang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)/bin/$(shell echo $(RUST_TARGET) | cut -f3 -d-)_$(shell echo $(MEMO_TARGET) | cut -f2 -d-)/go{,fmt} $(BUILD_STAGE)/golang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)/bin; \
	fi
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	mv $(BUILD_STAGE)/golang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)/pkg/tool/$(shell echo $(RUST_TARGET) | cut -f3 -d-)_$(shell echo $(MEMO_TARGET) | cut -f2 -d-)/link $(BUILD_STAGE)/golang$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)/pkg/tool/$(shell echo $(RUST_TARGET) | cut -f3 -d-)_$(shell echo $(MEMO_TARGET) | cut -f2 -d-)/link2
	$(CC) $(CFLAGS) -DLINKER="\"$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)/pkg/tool/$(shell echo $(RUST_TARGET) | cut -f3 -d-)_$(shell echo $(MEMO_TARGET) | cut -f2 -d-)/link2\"" -o $(BUILD_STAGE)/golang/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/go-$(GOLANG_MAJOR_V)/pkg/tool/$(shell echo $(RUST_TARGET) | cut -f3 -d-)_$(shell echo $(MEMO_TARGET) | cut -f2 -d-)/link $(BUILD_MISC)/ld-wrapper/wrapper.c
endif
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
