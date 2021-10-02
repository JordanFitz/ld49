require "constants"

-- https://stackoverflow.com/a/27028488/6238921
function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

-- https://gist.github.com/Uradamus/10323382#gistcomment-2754684
function shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

function add_vec(v1, v2) 
    v1.x = v1.x + v2.x
    v1.y = v1.y + v2.y
end

function square(x)
    return x*x
end

-- https://stackoverflow.com/a/18313481/6238921
function math.round(value) 
    return math.floor(value + 0.5)
end

-- adapted from https://gamedev.stackexchange.com/a/33146
function snap_to_tile(position)
    return {
        x = math.floor(position.x / TILE_SIZE) * TILE_SIZE,
        y = math.floor(position.y / TILE_SIZE) * TILE_SIZE
    }
end

-- adapted from https://stackoverflow.com/a/402010/6238921
function player_on_tile(player_position, tile_position)
    local half_tile = TILE_SIZE / 2

    -- this algorithm assumes the rect's x and y are at its center
    tile_position = {
        x = tile_position.x + half_tile,
        y = tile_position.y + half_tile
    }

    local circle_distance = {
        x = math.abs(player_position.x - tile_position.x),
        y = math.abs(player_position.y - tile_position.y)
    }

    if circle_distance.x > (half_tile + PLAYER_RADIUS) then return false end
    if circle_distance.y > (half_tile + PLAYER_RADIUS) then return false end

    if circle_distance.x <= half_tile then return true end
    if circle_distance.y <= half_tile then return true end

    corner_distance_sq = square(circle_distance.x - half_tile) + square(circle_distance.y - half_tile)

    return corner_distance_sq <= square(PLAYER_RADIUS)
end

function distance(v1, v2)
    return math.sqrt(
        square(v2.x - v1.x) + 
        square(v2.y - v1.y)
    )
end
