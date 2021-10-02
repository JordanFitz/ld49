require "util"
require "constants"
require "tile"
require "particles"
require "player"

game_state = GameState.PLAY
world_grid = {}
fill_style = nil
update_delta = 0

player = Player:new{
    position = {
        x = 10,
        y = 10
    },
    move_speed = 100,
    moving = false,
    target = nil
}

atom_cluster = ParticleCluster:new{
    position = {
        x = 50,
        y = 50
    },
    rotation = 0,
    move_speed = 25,
    moving = true,
    target = {
        x = 400,
        y = 400
    }
}

function canvas.onmousedown(event) 
    player.target = {
        x = event.clientX,
        y = event.clientY
    }
end

function canvas.onmouseup(event) 
    player.target = nil
end

function canvas.onmousemove(event) 
    if player.target ~= nil then 
        player.target = {
            x = event.clientX,
            y = event.clientY
        }
    end
end

function canvas.update(delta)
    update_delta = delta

    atom_cluster:rotate(delta / 1.5)

    if atom_cluster.moving then
        atom_cluster.moving = not atom_cluster:move_to(
            delta,
            atom_cluster.target.x,
            atom_cluster.target.y
        )
        -- TODO: Uncomment
        -- player.target = nil
    end

    if player.target ~= nil then
        player:move_towards(delta, player.target.x, player.target.y)
        player:clamp_to_screen()
        player.moving = true
    else
        player.moving = false
    end
end

function canvas.render()
    context.fill_style("#000")
    context.fill_rect(0, 0, SCREEN_SIZE, SCREEN_SIZE)
    fill_style = "#000"

    local break_out = false

    local nearest_tile = snap_to_tile(player.position)

    for y=1,#world_grid do
        local row = world_grid[y]

        for x=1,#row do
            local tile = row[x]

            if player.moving and tile.opacity > 0 and player_on_tile(player.position, tile.position) then
                tile.opacity = tile.opacity - (update_delta / 1.5)
                tile.opacity = math.floor(tile.opacity * 100) / 100
                if tile.opacity <= 0 then
                    tile.opacity = 0
                    -- TODO: tile gone!!
                end
            end

            if fill_style ~= get_tile_color_with_opacity(tile.opacity) then
                fill_style = get_tile_color_with_opacity(tile.opacity)
                context.fill_style(fill_style)
            end

            local tile_size = TILE_SIZE * tile.opacity
            local tile_position = {
                x = tile.position.x + (TILE_SIZE - tile_size) / 2, -- (TILE_SIZE-tile_size) ... :)
                y = tile.position.y + (TILE_SIZE - tile_size) / 2
            }

            -- context.fill_rect(tile.position.x, tile.position.y, TILE_SIZE, TILE_SIZE)

            context.fill_rect(tile_position.x, tile_position.y, tile_size, tile_size)

            if tile.position.x > SCREEN_SIZE then break end
            if tile.position.y > SCREEN_SIZE then
                break_out = true
                break
            end
        end

        if break_out then break end
    end

    atom_cluster:render(context)

    player:render(context)
end

function init()
    math.randomseed(os.time())

    canvas.use_vsync(true)
    canvas.max_framerate(60)

    canvas.width(SCREEN_SIZE)
    canvas.height(SCREEN_SIZE)

    fill_style = get_tile_color_with_opacity(1)
    context.fill_style(fill_style)

    atom_cluster:populate(25)

    for y=0,TILE_COUNT do
        local row = {}

        for x=0,TILE_COUNT do
            tile = Tile:new{
                position = {
                    x = x * TILE_SIZE,
                    y = y * TILE_SIZE
                },
                opacity = 1
            }

            table.insert(row, tile)
        end

        table.insert(world_grid, row)
    end
end

init()
