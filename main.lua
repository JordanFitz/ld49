require "util"
require "constants"
require "tile"
require "particles"
require "player"
require "fade_out"
require "fading_text"
require "text"

game_state = GameState.INTRO

world_grid = nil
player = nil
atom_cluster = nil
fade_out = nil
game_over_script = nil

hud_text = Text:new{
    text = "score: %d",
    color = HUD_FOREGROUND,
    size = 10,
    position = {
        x = 5,
        y = SCREEN_SIZE - HUD_HEIGHT + 3
    },
    format = {
        function() 
            return math.floor(player.score)
        end
    }
}

sound = {
    current_music = 1,

    music = {
        Audio:new("res/sound/music1.ogg", true),
        Audio:new("res/sound/music2.ogg", true),
        Audio:new("res/sound/music3.ogg", true),
        Audio:new("res/sound/music4.ogg", true),
    },

    explosions = {
        Audio:new("res/sound/explosion1.ogg"),
        Audio:new("res/sound/explosion2.ogg"),
        Audio:new("res/sound/explosion3.ogg"),
        Audio:new("res/sound/explosion4.ogg"),
        Audio:new("res/sound/explosion5.ogg"),
    },

    explosion_played = false
}

update_delta = 0

function canvas.onmousedown(event) 
    if game_state == GameState.DEAD or game_state == GameState.INTRO then
        game_state = GameState.PLAY
        start_game()
        return
    end

    if game_state ~= GameState.PLAY then return end

    player.target = {
        x = event.clientX,
        y = event.clientY
    }
end

function canvas.onmouseup(event) 
    if game_state ~= GameState.PLAY then return end
    player.target = nil
end

function canvas.onmousemove(event)
    if game_state ~= GameState.PLAY then return end

    if player.target ~= nil then 
        player.target = {
            x = event.clientX,
            y = event.clientY
        }
    end
end

function canvas.update(delta)
    update_delta = delta

    if not sound.music[sound.current_music]:playing() then
        sound.music[sound.current_music]:stop()
        sound.current_music = sound.current_music + 1
        if sound.current_music > #sound.music then
            shuffle(sound.music)
            sound.current_music = 1
        end
        sound.music[sound.current_music]:play()
    end

    if game_state == GameState.INTRO then
        if intro_script.current_text > #intro_script.texts then
            return
        end

        local text = intro_script.texts[intro_script.current_text]

        text:update(delta)

        if text.done then
            intro_script.current_text = intro_script.current_text + 1
        end

        return
    end

    if game_state == GameState.DEAD then
        if game_over_script.current_text > #game_over_script.texts then
            return
        end

        local text = game_over_script.texts[game_over_script.current_text]

        text:update(delta)

        if text.done then
            game_over_script.current_text = game_over_script.current_text + 1
        end

        return
    end

    if player.died then
        fade_out:update(delta)
        return 
    end

    atom_cluster:rotate(delta / 1.5)
    atom_cluster:update(delta, player)

    if atom_cluster.shake_screen then
        if not sound.explosion_played then
            sound.explosions[math.random(1,5)]:play()
            sound.explosion_played = true
        end

        canvas.view_position(
            math.random(-SCREEN_SHAKE_AMOUNT, SCREEN_SHAKE_AMOUNT),
            math.random(-SCREEN_SHAKE_AMOUNT, SCREEN_SHAKE_AMOUNT )
        )
    elseif canvas.view_position().x ~= 0 or canvas.view_position().y ~= 0 then
        canvas.view_position(0, 0)
        sound.explosion_played = false
    end

    if atom_cluster.moving then
        atom_cluster.moving = not atom_cluster:move_to(
            delta,
            atom_cluster.target.x,
            atom_cluster.target.y
        )

        if not atom_cluster.moving then
            -- player gets some points each time the atom explodes
            if player.score > 0 then
                player.score = player.score + PARTICLE_RETURN_SCORE
            end
            atom_cluster:expel_particles(math.random(3, 6))
        end

        -- player.target = nil
    end

    if player.target ~= nil then
        player:move_towards(delta, player.target.x, player.target.y)
        player:clamp_to_screen()
        player.moving = true

        player.score = player.score + delta * SCORE_FACTOR
    else
        player.moving = false
    end
end

function canvas.render()
context.clear_rect()

    if game_state == GameState.INTRO then
        for i=1,#intro_script.texts do
            intro_script.texts[i]:render(context)
        end

        return
    end

    if game_state == GameState.DEAD then
        for i=1,#game_over_script.texts do
            game_over_script.texts[i]:render(context)
        end

        return
    end

    local fill_style = nil

    local break_out = false
    local on_solid_tile = false

    for y=1,#world_grid do
        local row = world_grid[y]

        for x=1,#row do
            local tile = row[x]

            if tile.opacity > 0 and atom_cluster.healing_in_progress then
                tile.opacity = tile.opacity + atom_cluster.healing_amount
                if tile.opacity > 1 then
                    tile.opacity = 1
                end
            end

            local on_tile = player_on_tile(player.position, tile.position)

            if on_tile and tile.opacity > 0 then
                on_solid_tile = true
            end

            if player.moving and tile.opacity > 0 and on_tile then
                tile.opacity = tile.opacity - (update_delta / PLAYER_DAMAGE_FACTOR)
                if tile.opacity <= MINIMUM_TILE_OPACITY then tile.opacity = 0 end
            end

            if fill_style ~= get_tile_color_with_opacity(tile.opacity) then
                fill_style = get_tile_color_with_opacity(tile.opacity)
                context.fill_style(fill_style)
            end

            -- Shrink the tile as it gets lighter
            local tile_size = TILE_SIZE * tile.opacity 
            local tile_position = {
                x = tile.position.x + (TILE_SIZE - tile_size) / 2, -- notice: (TILE_SIZE-tile_size) ... high quality naming
                y = tile.position.y + (TILE_SIZE - tile_size) / 2
            }

            context.fill_rect(tile_position.x, tile_position.y, tile_size, tile_size)

            if tile.position.x > SCREEN_SIZE then break end
            if tile.position.y > SCREEN_SIZE then
                break_out = true
                break
            end
        end

        if break_out then break end
    end

    atom_cluster.healing_in_progress = false

    atom_cluster:render(context)

    player:render(context)

    context.fill_style(HUD_COLOR)
    context.fill_rect(0, SCREEN_SIZE - HUD_HEIGHT, hud_text:get_width(context).width + 10, HUD_HEIGHT)
    hud_text:render(context)

    if player.died then
        fade_out:render(context)
        if fade_out.done then
            game_state = GameState.DEAD
        end
        return 
    end

    if not on_solid_tile then
        player.died = true
        player.score = math.floor(player.score)
        fade_out.flash = Flash:new{
            done = false,
            opacity = 1
        }
    end
end

function start_game()
    world_grid = {}

    player = Player:new{
        position = {
            x = 15,
            y = 15
        },
        move_speed = 100,
        moving = false,
        target = nil,
        died = false,
        score = 0
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

    atom_cluster:populate(25)

    fade_out = FadeOut:new{
        opacity = 0,
        done = false
    }

    game_over_script = {
        current_text = 1,
        texts = {
            FadingText:new{
                text = "the abyss has reclaimed\n   your immortal soul",
                size = 20,
                opacity = 0,
                position = {
                    x = CENTER_TEXT,
                    y = 100
                }
            },
            FadingText:new{
                text = "you had a score of %d",
                size = 16,
                opacity = 0,
                position = {
                    x = CENTER_TEXT,
                    y = 250
                },
                format = {
                    function() 
                        return math.floor(player.score)
                    end
                }
            },
            -- FadingText:new{
            --     text = "is that what your soul is worth?",
            --     size = 14,
            --     opacity = 0,
            --     position = {
            --         x = CENTER_TEXT,
            --         y = 275
            --     }
            -- },
            FadingText:new{
                text = "[click anywhere to try again]",
                size = 11,
                opacity = 0,
                position = {
                    x = CENTER_TEXT,
                    y = 420
                }
            }
        }
    }

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

function init()
    intro_script = {
        current_text = 1,
        texts = {
            FadingText:new{
                text = "inparticulate",
                size = 35,
                opacity = 0,
                position = {
                    x = CENTER_TEXT,
                    y = 75
                }
            },
            FadingText:new{
                text = " you roam a world held together by the energy of a  \n"  ..
                       "  single unstable radioactive atom. unfortunately,  \n"  ..
                       " your movements absorb energy from the ground below \n"  ..
                       "you. as it disintegrates beanth your feet, you must \n"  ..
                       " collect and return expelled alpha particles to the \n"  ..
                       "atom. each particle ejection produces a small amount\n"  ..
                       " of energy which the world absorbs. avoid the abyss \n"  ..
                       "           below for as long as you can.",
                size = 12,
                opacity = 0,
                position = {
                    x = CENTER_TEXT,
                    y = 175
                }
            },
            FadingText:new{
                text = "[hold down your left mouse button to move]",
                size = 11,
                opacity = 0,
                position = {
                    x = CENTER_TEXT,
                    y = 390
                }
            },
            FadingText:new{
                text = "[click anywhere to begin]",
                size = 11,
                opacity = 0,
                position = {
                    x = CENTER_TEXT,
                    y = 420
                }
            }
        }
    }

    math.randomseed(os.time())

    canvas.title("inparticulate")

    -- canvas.use_vsync(true)
    -- canvas.max_framerate(60)

    canvas.width(SCREEN_SIZE)
    canvas.height(SCREEN_SIZE)

    canvas.background_color(BACKGROUND_COLOR)

    canvas.load_font("SourceCodePro", "res/scp.ttf")

    -- cache all of the variable opacity colors 
    -- by setting the fill_style to all of the variations
    for i=0,1.01,0.01 do
        context.fill_style(get_tile_color_with_opacity(i))
        context.fill_style(get_ripple_fill_color(i))
        context.fill_style(get_fade_out_fill_color(i))
    end

    context.fill_style(PLAYER_COLOR)
    context.fill_style(BACKGROUND_COLOR)
    context.fill_style(PLAYER_OUTLINE_COLOR)
    context.fill_style(RIPPLE_COLOR)
    context.fill_style(LIGHT_PARTICLE_COLOR)
    context.fill_style(DARK_PARTICLE_COLOR)

    sound.music[1]:play()
end

init()
