EXPECT_VERSION = 10
ifneq ($(shell find /bin/ -name "llvm-config*" | grep $(EXPECT_VERSION)), )
	CONFIG=$(shell find /bin/ -maxdepth 1 -name "llvm-config*" | grep $(EXPECT_VERSION) | cut -d \/ -f 3)
else
	CONFIG = llvm-config
endif

VERSION = $(shell $(CONFIG) --version)
VERSION_MAJOR = $(firstword $(subst ., ,$(VERSION)))

CONFIG_FILE = llvm_config.go
INCLUDE_DIR = include

.PHONY: check
check:
	@if [ $(VERSION_MAJOR) != $(EXPECT_VERSION) ]; then echo "[Error] need llvm$(EXPECT_VERSION)"; exit 1; fi

.PHONY: clean
clean:
	@rm -rf $(INCLUDE_DIR)
	@rm -f $(CONFIG_FILE)
	@rm -f .gitattributes

.PHONY: include
include:
	@rm -rf $(INCLUDE_DIR)
	@mkdir $(INCLUDE_DIR)
	@cp -r $(shell $(CONFIG) --includedir)/llvm* $(INCLUDE_DIR)/

.PHONY: gitattributes
gitattributes:
	@rm -f .gitattributes
	@for path in $(shell find $(INCLUDE_DIR) -type d); \
	do \
		echo "$$path/* linguist-vendored" >> .gitattributes; \
	done

.PHONY: config
config: check include gitattributes
	@rm -f $(CONFIG_FILE)
	@echo "//go:build !byollvm" >> $(CONFIG_FILE)
	@echo "// +build !byollvm" >> $(CONFIG_FILE)
	@echo "" >> $(CONFIG_FILE)
	@echo "package llvm" >> $(CONFIG_FILE)
	@echo "" >> $(CONFIG_FILE)
	@echo "// Automatically generated by \`make config\`, do not edit." >> $(CONFIG_FILE)
	@echo "" >> $(CONFIG_FILE)
	@echo "// #cgo CFLAGS: $(shell $(CONFIG) --cflags)" >> $(CONFIG_FILE)
	@echo "// #cgo CXXFLAGS: $(shell $(CONFIG) --cxxflags)" >> $(CONFIG_FILE)
	@echo "// #cgo LDFLAGS: $(shell $(CONFIG) --libs)" >> $(CONFIG_FILE)
	@echo "import \"C\"" >> $(CONFIG_FILE)
	@echo "" >> $(CONFIG_FILE)
	@echo "type run_build_sh int" >> $(CONFIG_FILE)