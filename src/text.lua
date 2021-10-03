require "util"

Text = {}

function Text:new(o) 
    o.parent = self
    setmetatable(o, self)
    self.__index = self
    return o
end

function Text:update(delta)
    
end

function Text:get_width(context)
    local text = fulfill_formatting(self.text, self.format)

    if self.old_text ~= text then
        context.font(get_font_string(self.size))
        self.width = context.measure_text(text).width
        self.old_text = text
    end
    
    return self.width
end

function Text:render(context)
    if self.centered == nil then
        self.centered = self.position.x == CENTER_TEXT
    end

    context.font(get_font_string(self.size))

    if self.position.x == CENTER_TEXT or (self.centered and self.old_width ~= self:get_width(context)) then
        self.position.x = SCREEN_SIZE / 2 - self:get_width(context) / 2
        self.old_width = self.width
    end

    local text = fulfill_formatting(self.text, self.format)

    context.fill_style(self.color)
    context.fill_text(
        text,
        self.position.x,
        self.position.y
    )
end
