require "util"

Tile = {}

function Tile:new(o) 
    o.parent = self
    return o
end
