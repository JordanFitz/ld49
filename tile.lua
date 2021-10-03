function get_tile_color_with_opacity(opacity)
    opacity = math.floor(opacity * 100) / 100
    return "rgba(180,180,180," .. tostring(opacity) .. ")"
end

Tile = {}

function Tile:new(o) 
    o.parent = self
    return o
end
