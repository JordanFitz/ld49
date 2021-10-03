require "util"

function get_fading_text_fill_color(opacity)
    opacity = math.floor(opacity * 100) / 100
    return "rgba(255,255,255," .. tostring(opacity) .. ")"
end

FadingText = {}

function FadingText:new(o) 
    o.parent = self
    setmetatable(o, self)
    self.__index = self
    return o
end

function FadingText:update(delta)
    if self.done then
        return
    end

    self.opacity = self.opacity + delta / 2

    if self.opacity > 1 then
        self.done = true
        self.opacity = 1
        return
    end
end

function FadingText:render(context)
    context.font(get_font_string(self.size))

    if self.position.x == CENTER_TEXT then
        self.position.x = SCREEN_SIZE / 2 -
            context.measure_text(self.text).width / 2
    end

    context.fill_style(get_fading_text_fill_color(self.opacity))
    context.fill_text(fulfill_formatting(self.text, self.format), self.position.x, self.position.y)
end
