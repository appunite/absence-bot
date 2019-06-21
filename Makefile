default: bootstrap-oss

SWIFT := $(if $(shell command -v xcrun 2> /dev/null),xcrun swift,swift)
HEROKU_STAGING_APP_NAME = "au-absence-bot-stage"
HEROKU_REGISTRY = "registry.heroku.com"

bootstrap-oss:
	@echo "  ⚠️  Bootstrapping open-source Absence-Bot..."
	@$(MAKE) xcodeproj-oss
	@echo "  ✅ Bootstrapped! Opening Xcode..."
	@sleep 1 && xed .

xcodeproj-oss:
	@echo "  ⚠️  Generating \033[1mAbsenceBot.xcodeproj\033[0m..."
	@$(SWIFT) package generate-xcodeproj --xcconfig-overrides=OSS.xcconfig >/dev/null \
		&& echo "  ✅ Generated!" \
		|| (echo "  🛑 Failed!" && exit 1)

.env: .env.example
	@echo "  ⚠️  Preparing local configuration..."
	@test -f .env && echo "$$DOTENV_ERROR" && exit 1 || true
	@cp .env.example .env
	@echo "  ✅ \033[1m.env\033[0m file copied!"

define DOTENV_ERROR
  🛑 Local configuration already exists at \033[1m.env\033[0m!

     Please reset the file:

       $$ \033[1mrm\033[0m \033[38;5;66m.env\033[0m

     Or manually edit it:

       $$ \033[1m$$EDITOR\033[0m \033[38;5;66minstall cmark\033[0m

endef
export DOTENV_ERROR

# colortheme

COLOR_THEMES_PATH = $(HOME)/Library/Developer/Xcode/UserData/FontAndColorThemes
COLOR_THEME = $(COLOR_THEMES_PATH)/Point-Free.xccolortheme

colortheme:
	@echo "  ⚠️  Installing \033[1mPoint-Free.xcolortheme\033[0m..."
	@mkdir -p $(COLOR_THEMES_PATH)
	@cp -r .PointFree.xccolortheme $(COLOR_THEME)
	@echo "  ✅ Installed!"

uninstall-colortheme:
	rm -r $(COLOR_THEME)

# sourcery

sourcery: sourcery-routes sourcery-tests

sourcery-routes:
	@echo "  ⚠️  Generating routes..."
	@mkdir -p ./Sources/AbsenceBot/__Generated__
	@.bin/sourcery \
		--quiet \
		--sources ./Sources/AbsenceBot/ \
		--templates ./.sourcery-templates/DerivePartialIsos.stencil \
		--output ./Sources/AbsenceBot/__Generated__/DerivedPartialIsos.swift
	@echo "  ✅ Generated!"

SOURCERY_TESTS_IMPORTS = \
	@testable import AbsenceBotTests;

sourcery-tests:
	@echo "  ⚠️  Generating tests..."
	@.bin/sourcery \
		--quiet \
		--sources ./Tests/ \
		--templates ./.sourcery-templates/LinuxMain.stencil \
		--output ./Tests/ \
		--args testimports='$(SOURCERY_TESTS_IMPORTS)'
	@mv ./Tests/LinuxMain.generated.swift ./Tests/LinuxMain.swift
	@echo "  ✅ Generated!"

# private

xcodeproj: 
	@echo "  ⚠️  Generating \033[1mAbsenceBot.xcodeproj\033[0m..."
	@$(SWIFT) package generate-xcodeproj --xcconfig-overrides=Development.xcconfig >/dev/null
	@xed .
	@echo "  ✅ Generated!"

linux-start:
	docker-compose up --build

env-local:
	heroku config --json -a $(HEROKU_STAGING_APP_NAME) > .env

deploy-local:
	@heroku container:login
	@heroku container:push web -a $(HEROKU_STAGING_APP_NAME)
	@heroku container:release web -a $(HEROKU_STAGING_APP_NAME)
# 	@docker login --username=_ --password=$(HEROKU_TOKEN) $(HEROKU_REGISTRY)
# 	@docker build -t $(HEROKU_REGISTRY)/$(HEROKU_STAGING_APP_NAME)/web .
# 	@docker push $(HEROKU_REGISTRY)/$(HEROKU_STAGING_APP_NAME)/web
# 	@docker run --rm -e HEROKU_API_KEY=$(HEROKU_TOKEN) wingrunr21/alpine-heroku-cli container:release web --app $(HEROKU_STAGING_APP_NAME)

test-linux: sourcery
	docker-compose up --abort-on-container-exit --build

test-oss: db
	@$(SWIFT) test -Xswiftc "-D" -Xswiftc "OSS"

clean-snapshots:
	find Tests -name "__Snapshots__" | xargs -n1 rm -fr
