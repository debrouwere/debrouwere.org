fs = require 'fs'
fs.path = require 'path'
{routing} = require 'hector'
espy = require 'espy'

# shortlinks are written away to both a NGINX config file and a 
# JSON file that can serve as a data source for our static site
# (allowing us to display the shortlink for the current article)
postDir = fs.path.join __dirname, '../../writing'
basedir = (segments...) -> fs.path.join postDir, segments...
shortlinksNGINXFile = basedir 'nginx.shortlinks.conf'
shortlinksJSONFile = basedir 'nginx.shortlinks.json'
stream = fs.createWriteStream shortlinksNGINXFile, {flags: 'a'}
list = JSON.parse fs.readFileSync shortlinksJSONFile, 'utf8'
# remove any space at the end of our log file and chunk it into individual instructions
shortlinks = (fs.readFileSync shortlinksNGINXFile, 'utf8').replace(/\s+$/).split '\n'
tail = shortlinks.slice(-1)[0]
# looks for the last shortlink (it's between regex start and 
# stop sigils) and parse it
counter = parseInt (tail.match /\^\/(\w+)\$\s/)?[1] or 0, 36

formats =
    filename: new routing.Format '{year:d}/{layout}/{month}-{day}-{title}'
    permalink: new routing.Format '/{year}/{month}/{day}/{title}/'

createShortLinks = (files) ->
    for post in files
        groups = isPost = formats.filename.match post
        permalink = formats.permalink.fill groups
        shortlinkMatches = shortlinks.filter (redirect) -> (redirect.indexOf permalink) isnt -1
        hasShortlink = shortlinkMatches.length
        if isPost and not hasShortlink
            counter++
            hexatri = counter.toString 36
            rewrite = "rewrite ^/#{hexatri}$ http://stdout.be#{permalink} permanent;\n"
            # it might seem odd to put this in a hash instead of in an array, but 
            # this data is usually queried by permalink, not by counter, making a
            # hash faster and more natural.
            list[permalink] = hexatri
            stream.write rewrite

    fs.writeFile shortlinksJSONFile, (JSON.stringify list, null, 4)


recursive = yes
espy.findFilesFor postDir, '', recursive, (filenames) ->
    relativeFileNames = filenames.map (file) -> file.replace postDir, ''
    createShortLinks relativeFileNames