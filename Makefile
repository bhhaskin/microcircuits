MOD_NAME := $(shell jq -r .name info.json)
VERSION  := $(shell jq -r .version info.json)
RELEASE  := $(MOD_NAME)_$(VERSION)
BUILD    := build
STAGE    := $(BUILD)/$(RELEASE)
ZIP      := $(BUILD)/$(RELEASE).zip

# Files and folders shipped in the release zip
RELEASE_FILES := info.json changelog.txt thumbnail.png LICENSE \
                 control.lua data.lua data-final-fixes.lua settings.lua \
                 data graphics locale scripts

.PHONY: all build test test-unit test-game clean

all: test build

## build: package the mod as build/<name>_<version>.zip
build:
	rm -rf $(STAGE) $(ZIP)
	mkdir -p $(STAGE)
	cp -r $(RELEASE_FILES) $(STAGE)/
	sed -i '/^-- BEGIN TESTS/,/^-- END TESTS/d' $(STAGE)/control.lua
	cd $(BUILD) && zip -qr9 $(RELEASE).zip $(RELEASE)
	rm -rf $(STAGE)
	@echo "Built $(ZIP)"

## test: run unit and in-game tests
test: test-unit test-game

## test-unit: busted unit tests (Docker)
test-unit:
	npm run --silent test:unit

## test-game: in-game tests in headless Factorio (Docker)
test-game:
	npm run --silent test:game

## clean: remove build output and test data
clean:
	rm -rf $(BUILD) .factorio-test-data factorio-test-results.json
