# if -B or --always-make is specified, --force should be 
# passed to the `gather` command
ifneq (,$(findstring B,$(MAKEFLAGS)))
	FORCE = --force
endif

all: assets pages posts feeds shortlinks media

build/data/pages.json: ../writing
	mkdir -p build/data
	yaml2json ../writing/pages \
		--prose \
		--output build/data/writing/pages
	gather 'build/data/writing/pages/{language:s}/{slug:s}.json' \
		--pretty \
		--output build/data/pages.json \
		$(FORCE)
	refract build/data/pages.json \
		--each \
		--template defaults/page.yml \
		--missing --in-place

build/data/posts.json: ../writing
	mkdir -p build/data
	yaml2json ../writing \
		--prose \
		--output build/data/writing
	gather 'build/data/writing/{year:Y}/{category:s}/{month:m}-{day:d}-{slug:s}.json' \
		--indent \
		--annotate \
		--output build/data/posts.json \
		$(FORCE)
	# add permalinks and shortlinks
	# if no title is present, generate one from the slug
	refract build/data/posts.json \
		--each \
		--template defaults/post.yml \
		--helpers tools/shortlinks.coffee \
		--missing --in-place
	# create per-language JSON for our feeds
	ln -sf $(CURDIR)/build/data/posts.json $(CURDIR)/build/data/all.json
	groupby build/data/posts.json 'build/data/{language}.json'

shortlinks: ../writing/shortlinks.json
	jq '. | to_entries | .[] | "\(.value) \(.key)"' \
		../writing/shortlinks.json \
		--raw-output > build/data/shortlinks.csv

pages: build/data/pages.json layouts assets
	render 'layouts/{layout}.jade' \
		--context build/data/pages.json \
		--output 'build/{language}/{slug}/' \
		--newer-than date.modified.iso $(FORCE) \
		--many \
		--verbose

posts: build/data/posts.json shortlinks layouts assets
	render 'layouts/{category}.detail.jade' \
		--context build/data/posts.json \
		--globals defaults/globals.yml \
		--output 'build/{year}/{month}/{day}/{slug}/' \
		--newer-than date.modified.iso $(FORCE) \
		--fast \
		--many \
		--verbose

feeds: build/data/posts.json layouts/feed.jade
	refract \
		--new --template defaults/site.yml \
		--helpers tools/date.coffee \
		> build/data/site.json
	for language in all en nl;					\
	do 								\
		render 'layouts/feed.jade' 				\
			--context posts:build/data/$$language.json	\
			--globals build/data/site.json 			\
			--output build/feeds/$$language.atom 		\
			--fast 						\
			--verbose					\
			$(FORCE);					\
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
