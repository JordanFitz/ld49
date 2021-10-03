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
        self.width = context.measure_text(text)
        self.old_text = text
    end
    
    return self.width
end

function Text:render(context)
    context.font(get_font_string(self.size))

    local text = fulfill_formatting(
        self.text, self.format
    )

    if self.position.x == CENTER_TEXT then
        self.position.x = SCREEN_SIZE / 2 -
            context.measure_text(text).width / 2
    end

    context.fill_style(self.color)
    context.fill_text(
        text,
        self.position.x,
        self.position.y
    )
end
