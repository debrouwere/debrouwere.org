# if -B or --always-make is specified, --fresh should be 
# passed to the `gather` command
ifneq (,$(findstring B,$(MAKEFLAGS)))
	FRESH = --fresh
endif

all: assets pages posts feeds shortlinks media

build/data/pages.json: ../writing
	mkdir -p build/data
	gather '../writing/pages/{language:s}/{slug:s}' \
		--pretty \
		--output build/data/pages.json \
		$(FRESH)
	jq 'map(.permalink = "/\(.language)/\(.slug)/")' \
		build/data/pages.json --in-place

# TODO: it's probably better to add in any defaults
# at *this* stage rather than the rendering stage
# (perhaps a nice `defaults` cli with support for 
# #{placeholders} that we'll eval w/ CoffeeScript, 
# and any program.args A=B are added too?
# and --in-place? and works with objects and arrays?
build/data/posts.json: ../writing
	mkdir -p build/data
	gather '../writing/{year:Y}/{category:s}/{month:m}-{day:d}-{slug:s}' \
		--pretty \
		--output build/data/posts.json \
		$(FRESH)
	# add permalinks
	jq 'map(.permalink = "/\(.date.inferred.path)/\(.slug)/")' \
		build/data/posts.json --in-place
	# generate a title if it isn't there already, 
	# using the post slug
	./tools/titleize
	# create per-language JSON for our feeds
	ln -sf $(CURDIR)/build/data/posts.json $(CURDIR)/build/data/all.json
	jq 'map(select(.language != "nl"))' build/data/posts.json \
		> build/data/en.json
	jq 'map(select(.language == "nl"))' build/data/posts.json \
		> build/data/nl.json

shortlinks: tools/generate-shortlinks ../writing/shortlinks.json
	tools/generate-shortlinks
	jq '. | to_entries | .[] | "\(.value) \(.key)"' \
		../writing/shortlinks.json \
		--raw-output > build/data/shortlinks.csv

pages: build/data/pages.json layouts assets
	render 'layouts/{layout}.jade' \
		--context build/data/pages.json \
		--output 'build/{language}/{slug}/' \
		--newer-than date.modified.iso $(FRESH) \
		--many

posts: build/data/posts.json shortlinks layouts assets
	render 'layouts/{category}.detail.jade' \
		--context build/data/posts.json \
		--globals globals.yml,defaults.yml \
		--output 'build/{year}/{month}/{day}/{slug}/' \
		--newer-than date.modified.iso $(FRESH) \
		--many

feeds: build/data/posts.json layouts/feed.jade
	./tools/date | jq '{site: {date: .}, language: null}' > build/data/site.json
	for language in all en nl;					\
	do 								\
		render 'layouts/feed.jade' 				\
			--context posts:build/data/$$language.json	\
			--globals build/data/site.json,defaults.yml 	\
			--output build/feeds/$$language.atom 		\
			$(FRESH);					\
	done

.PHONY: assets
assets:
	mkdir -p build/assets/{scripts,stylesheets}
	cp -r assets/images build/assets
	cp assets/images/favicon.png build/favicon.ico
	coffee --output build/assets/scripts --compile assets/scripts
	stylus assets/stylesheets --out build/assets/stylesheets

media:
	put --link \
		'../writing/{year:Y}/media/{slug:s}' \
		'build/images/content/{year}-{slug}'

clean:
	rm -r build

serve:
	serve ./build --watch . --target all --reload --inject --open

n ?= 1
.PHONY: redirects
redirects:
	tail -n $(n) build/data/shortlinks.csv | 			\
	while read shortlink permalink;					\
	do 								\
		aws s3 cp /dev/null s3://debrouwere.org$$shortlink	\
			--website-redirect $$permalink			\
			--profile debrouwere.org;			\
	done

upload: redirects
	aws s3 sync build s3://debrouwere.org \
		--exclude 'data/*' \
		--profile debrouwere.org

debrouwere.org:
	aws s3 mb s3://debrouwere.org

defaults:
	aws s3 cp /dev/null s3://debrouwere.org/index.html \
		--website-redirect /en/about-me/ \
		--profile debrouwere.org
	aws s3 website s3://debrouwere.org \
		--index-document index.html \
		--error-document error.html \
		--profile debrouwere.org

legacy:
	while read source destination;				\
	do 							\
		aws s3 cp /dev/null s3://debrouwere.org$$source	\
			--website-redirect $$destination 	\
			--profile debrouwere.org;		\
	done < redirects/legacy.csv
