function get_fade_out_fill_color(opacity)
    opacity = math.floor(opacity * 100) / 100
    return "rgba(0,0,0," .. tostring(opacity) .. ")"
end

FadeOut = {}

function FadeOut:new(o) 
    o.parent = self
    setmetatable(o, self)
    self.__index = self
    return o
end

function FadeOut:update(delta)
    if self.done then
        return
    end

    if self.flash then
        if self.flash.done then
            self.flash = nil
        else
            self.flash:update(delta)
        end
    end

    self.opacity = self.opacity + delta / 2.25

    if self.opacity > 1 then
        self.done = true
        self.opacity = 1
        return
    end
end

function FadeOut:render(context)
    context.fill_style(get_fade_out_fill_color(self.opacity))
    context.fill_rect(0, 0, SCREEN_SIZE, SCREEN_SIZE)

    if self.flash then
        self.flash:render(context)
    end
end
