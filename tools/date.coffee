exports.date = (date) ->
    if not date
        date = new Date()
    else if parseInt date
        while date.length < 13
            date += '0'
        date = new Date parseInt date
    else
        date = new Date date

    if date.getTime()
        (require 'date-expand') date
    else
        throw new Error "Cannot create date."