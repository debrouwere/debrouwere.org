pages.json:
	mkdir -p build/data
	gather '../writing/pages/{language}/{permalink}' > build/data/pages.json

posts.json:
	mkdir -p build/data
	gather '../writing/{year}/{category}/{month}-{day}-{permalink}' > build/data/posts.json

pages: pages.json
	render 'layouts/{layout}.jade' \
		--input build/data/pages.json
		--output 'build/{language}/{permalink}/'	

posts: posts.json
	render 'layouts/{layout}.detail.jade' \
		--input globals.yml build/data/posts.json \
		--output 'build/{year}/{month}/{day}/{permalink}/'

feeds: posts.json
	render 'layouts/feed.jade' \
		--input globals.yml build/data/posts.json \
		--output 'build/{language}/feed.atom' \
		--group

shortlinks:

assets:
	cp -r assets/images build/assets
	coffee --compile --output build/assets/scripts assets/scripts
	stylus assets/stylesheets --out build/assets/stylesheets

media:
	gather '../writing/{year}/media/{permalink}' \
		--output 'build/images/content/{year}-{permalink}'

writing: posts feeds shortlinks media

all: writing pages assets

serve:
	serve ./build --watch . --reload --inject --open

debrouwere.org:
	aws s3 mb s3://debrouwere.org

defaults: pages
	aws s3 s3://debrouwere.org \
		--index-document index.html \
		--error-document build/pages/error.html

upload:
	aws s3 sync build s3://debrouwere.org --exclude build/data

_upload:
	touch build/empty
	while read shortlink key; 							\
	do 													\
		aws s3 cp empty s3://debrouwere.org/$shortlink 	\ 
			--website-redirect $key;					\
	done < redirects.csv