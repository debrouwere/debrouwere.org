addLatest = (context, posts) ->
    latest = (list) -> list.slice -10

    context.stdout.latest =
        all: latest posts
        nl: latest posts.filter (post) -> post.meta.language is 'nl'
        en: latest posts.filter (post) -> post.meta.language is 'en'
        opennews: latest posts.filter (post) -> post.meta.stream is 'opennews'

addTime = (context) ->
    context.site = 
        time: new Date().toISOString()

module.exports = (context, callback) ->
    context.stdout ?= {}
    addLatest context, @router.data.posts
    addTime context

    callback null, context