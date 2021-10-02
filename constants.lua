GameState = {
    MENU = 1,
    PLAY = 2
}

SCREEN_SIZE = 500
TILE_SIZE = 50
TILE_COUNT = SCREEN_SIZE / TILE_SIZE
PARTICLE_RADIUS = 5
TAU = 6.283185307179586

function get_tile_color_with_opacity(opacity)
    return "rgba(180,180,180," .. tostring(opacity) .. ")"
end