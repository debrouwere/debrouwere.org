fs = require 'fs'
fs.path = require 'path'
_ = require 'underscore'

shortlinksPath = fs.path.join __dirname, '../../writing/nginx.shortlinks.json'
shortlinks = JSON.parse fs.readFileSync shortlinksPath, 'utf8'

addNameSpace = (context) ->
    context.stdout ?= {}

addShortLinks = (context) ->
    current = '/' + context.hector.permalink
    shortlink = shortlinks[current]    
    context.stdout.shortlink = 
        raw: shortlink
        human: "<a href=\"http://stdout.be/#{shortlink}\">stdout.be/#{shortlink}</a>"

addDateHelpers = (context) ->
    meta = context.meta
    year = parseInt meta.year
    month = -1 + parseInt meta.month
    day = parseInt meta.day
    meta.date = new Date(year, month, day)
    meta.date.human = meta.date.toDateString()
    meta.date.calendar = [meta.year, meta.month, meta.day].join('-')
    meta.date.iso = meta.date.toISOString()

module.exports = (contexts, callback) ->
    contexts.forEach addNameSpace
    contexts.forEach addDateHelpers
    contexts.forEach addShortLinks

    contexts = _.sortBy contexts, (context) -> context.meta.date.getTime()

    callback null, contexts