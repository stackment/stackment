

all:
	@echo "Please run a specific target"

gen-ffi:
	cd app/skmtdart && flutter config --no-analytics;
	cd app/skmtdart && cargo make linux;

linux-debug: gen-ffi
	@echo "Building linux desktop"

linux-debug-run: linux-debug
	cd app/skmtapp && flutter run -d linux;

linux-release:

linux-release-bundle:

android-debug: gen-ffi
	@echo "Building Android debug build"
	cd app/skmtapp && flutter build apk --debug; # --split-per-abi

android-release:

android-release-bundle:



