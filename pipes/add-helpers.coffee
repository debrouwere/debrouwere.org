addBioLinks = (context) ->
    context.stdout.me = 
        en: '<a href="/nl/wie-ben-ik/">Stijn Debrouwere</a>'
        nl: '<a href="/en/about-me/">Stijn Debrouwere</a>'
        twitter: '<a href="https://twitter.com/stdbrouw">@stdbrouw</a>'

module.exports = (context, callback) ->
    context.stdout ?= {}
    addBioLinks context

    callback null, context