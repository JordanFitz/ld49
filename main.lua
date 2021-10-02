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
    moving = false
}

test_cluster = ParticleCluster:new{
    position = {
        x = 50,
        y = 50
    },
    rotation = 0
}

moving_towards = nil

function canvas.onmousedown(event) 
    move_towards = {
        x = event.clientX,
        y = event.clientY
    }
end

function canvas.onmouseup(event) 
    move_towards = nil
end

function canvas.onmousemove(event) 
    if move_towards ~= nil then 
        move_towards = {
            x = event.clientX,
            y = event.clientY
        }
    end
end

function canvas.update(delta)
    update_delta = delta

    local cluster_move_amount = (delta / 2) * (SCREEN_SIZE - test_cluster.position.x)

    if SCREEN_SIZE - test_cluster.position.x < 10 then
        cluster_move_amount = 0
    end

    test_cluster:move(cluster_move_amount, cluster_move_amount)
    test_cluster:rotate(delta / 1.5)

    if move_towards ~= nil then
        player:move_towards(delta, move_towards.x, move_towards.y)
        player:clamp_to_screen()
        player.moving = true
    else
        player.moving = false
    end
end

function canvas.render()
    -- context.clear_rect()

    context.fill_style("#000")
    context.fill_rect(0, 0, SCREEN_SIZE, SCREEN_SIZE)
    fill_style = "#000"

    local break_out = false

    local nearest_tile = snap_to_tile(player.position)

    for y=1,#world_grid do
        local row = world_grid[y]

        for x=1,#row do
            local tile = row[x]

            if player.moving and player_on_tile(player.position, tile.position) then
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

            context.fill_rect(tile.position.x, tile.position.y, TILE_SIZE, TILE_SIZE)

            if tile.position.x > SCREEN_SIZE then break end
            if tile.position.y > SCREEN_SIZE then
                break_out = true
                break
            end
        end

        if break_out then break end
    end

    test_cluster:render(context)

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

    test_cluster:populate(25)

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
