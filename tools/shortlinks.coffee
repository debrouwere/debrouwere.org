fs = require 'fs'
fs.path = require 'path'
_ = require 'underscore'

here = (segments...) -> fs.path.join __dirname, '..', segments...

shortlinksPath = here '../writing/shortlinks.json'
shortlinks = JSON.parse fs.readFileSync shortlinksPath

counter = _.max _.map shortlinks, (link) -> parseInt link, 36

exports.shortlink = (permalink) ->
    unless shortlink = shortlinks[permalink]
        counter++
        hexatri = counter.toString 36
        shortlinks[permalink] = shortlink = '/' + hexatri
        fs.writeFileSync shortlinksPath, JSON.stringify shortlinks, undefined, 2
        console.log "Adding shortlink #{shortlink} for #{permalink}"

    shortlink
