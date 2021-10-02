function get_ripple_fill_color(opacity)
    return "rgba(255,255,255," .. tostring(opacity) .. ")"
end

Ripple = {}

function Ripple:new(o) 
    o.parent = self
    setmetatable(o, self)
    self.__index = self
    return o
end

function Ripple:update(delta)
    if self.done then
        return
    end

    self.radius = self.radius + delta * 200

    if self.generating_circles and (self.radius - self.last_radius > 25) then
        self.last_radius = self.radius
        table.insert(self.circles, {
            radius = 0,
            speed = 500 + 500/(#self.circles+1),
            opacity = 1
        })
    end

    for i=1,#self.circles do
        local circle = self.circles[i]
        circle.radius = circle.radius + delta * circle.speed 
        circle.opacity = circle.opacity  - delta * 1.1
        circle.opacity = math.floor(circle.opacity * 100) / 100

        if circle.opacity < 0 then
            circle.opacity = 0
        end
    end

    if #self.circles > 0 and self.circles[1].radius > DIAGONAL_SCREEN_SIZE then
        self.generating_circles = false
    end
end

function Ripple:render(context)
    if self.done then
        return
    end

    local stroke_style = context.stroke_style()
    context.stroke_style(RIPPLE_COLOR)
    local fill_style = context.fill_style()
    

    for i=1,#self.circles do
        local circle = self.circles[i]

        if not self.generating_circles and i == #self.circles and circle.radius > DIAGONAL_SCREEN_SIZE then
            self.done = true
        end

        context.begin_path()
        context.arc(
            self.origin.x,
            self.origin.y,
            circle.radius,
            0, 0
        )

        context.stroke()

        context.fill_style(get_ripple_fill_color(circle.opacity))
        context.fill()
    end

    context.stroke_style(stroke_style)
    context.fill_style(fill_style)
end
