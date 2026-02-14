SCHEME = Reapptivate
PROJECT = Reapptivate.xcodeproj
DESTINATION ?= 'platform=iOS Simulator,name=iPhone 17 Pro'
RESULT_BUNDLE = build/test-results.xcresult

.PHONY: generate test test-ui coverage clean

generate:
	xcodegen generate

test: generate
	@rm -rf $(RESULT_BUNDLE)
	xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-sdk iphonesimulator \
		-destination $(DESTINATION) \
		-resultBundlePath $(RESULT_BUNDLE) \
		-only-testing:ReapptivateTests \
		CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

test-ui: generate
	xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-sdk iphonesimulator \
		-destination $(DESTINATION) \
		-only-testing:ReapptivateUITests \
		CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO

coverage:
	@if [ -d "$(RESULT_BUNDLE)" ]; then \
		xcrun xccov view --report $(RESULT_BUNDLE); \
	else \
		echo "No test results found. Run 'make test' first."; \
	fi

clean:
	@rm -rf build/
	xcodebuild clean -project $(PROJECT) -scheme $(SCHEME)
