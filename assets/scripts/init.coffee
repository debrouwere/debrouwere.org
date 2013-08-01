###
Typekit
###

try
    Typekit.load()

###
Google Analytics
###

GOOGLE_ANALYTICS =
    account: 'UA-12933299-1'
    domain: 'stdout.be'

_gaq = _gaq or []
_gaq.push ['_setAccount', GOOGLE_ANALYTICS.account]
_gaq.push ['_trackPageview']
_gaq.push ['_setDomainName', GOOGLE_ANALYTICS.domain]

do ->
    https = 'https:' is document.location.protocol
    ga = document.createElement 'script'
    ga.src = (if https then 'https://ssl' else 'http://www') + '.google-analytics.com/ga.js'
    ga.setAttribute 'async', 'async'
    document.documentElement.firstChild.appendChild ga