//other_post_draw.gml
if ("other_player_id" not in self) exit;

//===================================================
// Strong buffering
if (being_buffered_by == other_player_id)
{
    draw_sprite(other_player_id.vfx_buffering, 
               (floor(get_gameplay_time()/4) % 8), x, y-char_height/2);
}