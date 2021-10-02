require "util"

Player = {}

function Player:new(o) 
    o.parent = self
    setmetatable(o, self)
    self.__index = self
    return o
end

function Player:move_towards(d, x, y)
    local delta = {
        x = x - self.position.x,
        y = y - self.position.y
    }

    local abs_delta = {
        x = math.abs(delta.x),
        y = math.abs(delta.y)
    }

    local min_distance = d * self.move_speed

    if abs_delta.x < min_distance and abs_delta.y < min_distance then 
        self.position = {
            x = x,
            y = y
        }
        return
    end

    local angle = math.atan2(delta.y, delta.x)

    local speed = d * self.move_speed * (((abs_delta.x + abs_delta.y) / 2) / 20)

    if speed < d * self.move_speed then
        speed = d * self.move_speed
    end

    local move_amount = {
        x = speed * math.cos(angle),
        y = speed * math.sin(angle)
    }

    add_vec(self.position, move_amount)
end

function Player:render(context)
    self.color = self.color or PLAYER_COLOR
    self.outline_color = self.outline_color or PLAYER_OUTLINE_COLOR

    context.arc(
        self.position.x, 
        self.position.y,
        PLAYER_RADIUS,
        0, 0
    )

    local fill_style = context.fill_style()
    context.fill_style(self.color)
    context.fill()
    context.fill_style(fill_style)

    local stroke_style = context.stroke_style()
    context.stroke_style(self.outline_color)
    context.stroke()
    context.stroke_style(stroke_style)
end

function Player:clamp_to_screen()
    if self.position.x - PLAYER_RADIUS < 0 then
        self.position.x = PLAYER_RADIUS
    end

    if self.position.x + PLAYER_RADIUS > SCREEN_SIZE then
        self.position.x = SCREEN_SIZE - PLAYER_RADIUS
    end

    if self.position.y - PLAYER_RADIUS < 0 then
        self.position.y = PLAYER_RADIUS
    end

    if self.position.y + PLAYER_RADIUS > SCREEN_SIZE then
        self.position.y = SCREEN_SIZE - PLAYER_RADIUS
    end
end
