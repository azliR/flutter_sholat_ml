
## Setup Commands ----------------------------------------

## Note: In windows, recommended terminal is cmd 

clean: ## Delete the build/ and .dart_tool/ directories
	flutter clean
	
pub_clean: ## Empties the entire system cache to reclaim extra disk space or remove problematic packages
	flutter pub cache clean	

pub_get: ## Gets pubs
	flutter pub get

pub_outdated: ## Check for outdated packages
	flutter pub outdated

pub_repair: ## Performs a clean reinstallation of all packages in your system cache
	flutter pub cache repair

build_runner: ## This command generates the files for the code generated dependencies
	dart run build_runner build -d

build_runner_watch: ## This command generates the files for the code generated dependencies 'automatically during development' 
	dart run build_runner watch -d

format: ## This command formats the codebase and run import sorter
	dart format lib test

clean_rebuild: clean pub_clean pub_get l10n build_runner format lint fix_lint

rebuild: pub_get l10n build_runner format lint fix_lint

lint: ## Analyzes the codebase for issues
	flutter analyze lib test
	dart analyze lib test

fix_lint: ## Fixes lint issues
	dart fix --apply

icons_launcher: ## This command runs icons_launcher
	dart run icons_launcher:create

native_splash: ## This command runs flutter_native_splash
	dart run flutter_native_splash:create

dependency_validator: ## This command runs dependency_validator
	dart run dependency_validator		

release_android:
	flutter build apk --split-per-abi --flavor production --target lib/main_production.dart