Tile = {}

function get_tile_color_with_opacity(opacity)
    return "rgba(180,180,180," .. tostring(opacity) .. ")"
end

function Tile:new(o) 
    o.parent = self
    return o
end
