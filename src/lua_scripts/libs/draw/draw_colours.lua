local draw_colours = {}

-- highlight is bright yellow, useful for a "can click here" move
-- alt highlight is blue (useful for highlighting a selected piece, where the
--                        yellow highlight is used to show possible destinations)
--
-- "..._remote" variants are for network multiplayer, to show what the
-- other player is doing.

draw_colours.HIGHLIGHT_OUTLINE            = '#ffff44'
draw_colours.HIGHLIGHT_FILL               = '#ffff9966'

draw_colours.ALT_HIGHLIGHT_OUTLINE        = '#00ffff'
draw_colours.ALT_HIGHLIGHT_FILL           = '#00ffff88'

draw_colours.HIGHLIGHT_OUTLINE_REMOTE     = '#88885588'
draw_colours.HIGHLIGHT_FILL_REMOTE        = '#ffffcc88'

draw_colours.ALT_HIGHLIGHT_OUTLINE_REMOTE = '#88cccc88'
draw_colours.ALT_HIGHLIGHT_FILL_REMOTE    = '#88cccc88'


return draw_colours
