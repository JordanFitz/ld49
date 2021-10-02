function random_particle_color()
    if math.random(0,1) == 0 then
        return "rgba(0,0,0,0.55)"
    end

    return "rgba(255,255,255,0.55)"
end

SingleParticle = {}

function SingleParticle:new(o)
    o.parent = self
    setmetatable(o, self)
    self.__index = self
    return o
end

function SingleParticle:render(context)
    self.color = self.color or random_particle_color()

    context.arc(
        self.position.x, 
        self.position.y,
        PARTICLE_RADIUS,
        0, 0 -- start and end angle = 0 causes Luau to render an sf::CircleShape 
             -- instead of doing the expensive process of computing an arc.
    )

    local fill_style = context.fill_style()
    context.fill_style(self.color)
    context.fill()
    context.fill_style(fill_style)
end

ParticleCluster = {}

function ParticleCluster:new(o)
    o.parent = self
    setmetatable(o, self)
    self.__index = self
    return o
end

function ParticleCluster:populate(cluster_radius)
    self.particle_meta = self.particle_meta or {}
    self.particles = self.particles or {}

    for radius=cluster_radius,0,-PARTICLE_RADIUS do
        local circum = radius*TAU
        local interval = TAU/(circum/(PARTICLE_RADIUS*2))
        for angle=0,TAU,interval do
            meta = {
                radius = radius,
                angle = angle,
                random = {
                    x = math.random(),
                    y = math.random(),
                }
            }

            table.insert(self.particle_meta, meta)

            table.insert(self.particles, SingleParticle:new{})
        end
    end

    shuffle(self.particle_meta)

end

function ParticleCluster:render(context)
    for i=1,#self.particle_meta do
        local meta = self.particle_meta[i]
        local particle = self.particles[i]

        particle.raw_position = {
            x = (meta.radius * math.cos(self.rotation + meta.angle)) + meta.random.x,
            y = (meta.radius * math.sin(self.rotation + meta.angle)) + meta.random.y
        }

        particle.position = {
            x = self.position.x + particle.raw_position.x,
            y = self.position.y + particle.raw_position.y
        }

        particle:render(context)
    end
end

-- Returns whether the cluster is at its target
function ParticleCluster:move_to(d, x, y)
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

        return true
    end

    local angle = math.atan2(delta.y, delta.x)

    local speed = d * self.move_speed * (((abs_delta.x + abs_delta.y) / 2) / 20)

    if speed < d * self.move_speed then
        speed = d * self.move_speed
    end

    self:move(
        speed * math.cos(angle),
        speed * math.sin(angle)
    )

    return false
end

function ParticleCluster:move(x, y)
    self.position.x = self.position.x + x
    self.position.y = self.position.y + y
end

function ParticleCluster:rotate(amount)
    self.rotation = self.rotation + amount

    if self.rotation >= TAU then
        self.rotation = 0
    end
end
