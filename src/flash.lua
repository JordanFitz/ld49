function get_flash_fill_color(opacity)
    opacity = math.floor(opacity * 100) / 100
    return "rgba(255,255,255," .. tostring(opacity) .. ")"
end

Flash = {}

function Flash:new(o) 
    o.parent = self
    setmetatable(o, self)
    self.__index = self
    return o
end

function Flash:update(delta)
    if self.done then
        return
    end

    self.opacity = self.opacity - delta

    if self.opacity < 0 then
        self.done = true
        self.opacity = 0
        return
    end
end

function Flash:render(context)
    if self.done then
        return
    end

    context.fill_style(get_flash_fill_color(self.opacity))
    context.fill_rect(0, 0, SCREEN_SIZE, SCREEN_SIZE)
end
