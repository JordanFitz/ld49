require "util"
require "constants"
require "tile"
require "particles"

game_state = GameState.PLAY
world_grid = {}

test_cluster = ParticleCluster:new{
    position = {
        x = 50,
        y = 50
    },
    rotation = 0
}

test_cluster:populate(25)

function canvas.update(delta)

    local cluster_move_amount = (delta / 2) * (SCREEN_SIZE - test_cluster.position.x)

    if SCREEN_SIZE - test_cluster.position.x < 10 then
        cluster_move_amount = 0
    end

    test_cluster:move(cluster_move_amount, cluster_move_amount)
    test_cluster:rotate(delta / 1.5)
end

function canvas.render()
    context.clear_rect()

    local fill_style = get_tile_color_with_opacity(1)
    context.fill_style(fill_style)

    local break_out = false

    for y=1,#world_grid do
        local row = world_grid[y]

        for x=1,#row do
            local tile = row[x]

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
end

function init()
    math.randomseed(os.time())

    canvas.use_vsync(true)
    canvas.max_framerate(60)

    canvas.width(SCREEN_SIZE)
    canvas.height(SCREEN_SIZE)

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
