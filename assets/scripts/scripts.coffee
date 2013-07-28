###
Homepage
###

toggle_all = ->
    checked = $(this).attr('checked')
    $(this).closest('div.filter').find('input:enabled').attr('checked', checked)

filter_rows = (checked) ->
    rows = $()
    checked.each ->
        show = $(this).attr('checked');
        if show
            type = $(this).attr('id').split('-')[1]
            matches = $('.', + type).closest('tr')
            rows = rows.add(matches)
    return rows

redraw_latest_writing = (checked) ->
        $('table#latest-writing tr').hide()
        filter_rows(checked).slice(0, 7).show()
        return false

filter_toggle = (checkboxes, toggle) ->
    ->
        # filter rows
        redraw_latest_writing checkboxes
        
        # if every type is checked, the global toggle should be checked as well
        # and vice versa
        total = checkboxes.length
        active = (checkboxes.filter -> $(this).attr 'checked').length
        if total is active
            toggle.attr 'checked', true
        else
            toggle.attr 'checked', false

$(document).ready ->
    # hide all permalinks
    # show a permalink when hovering over a comment
    $('a.permalink').hide()
    $('article.comment').hover ->
        $(this).find('a.permalink').toggle()

    # manage / instantiate the toggling mechanism
    toggle = $('div.filter input.toggle')
    checkboxes = $('div.filter input:enabled').not('input.toggle')
    
    redraw_latest_writing(checkboxes)
    toggle.click(toggle_all)
    checkboxes.add(toggle).click(filter_toggle checkboxes, toggle)
