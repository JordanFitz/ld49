function random_particle_color()
    if math.random(0,1) == 0 then
        return DARK_PARTICLE_COLOR
    end

    return LIGHT_PARTICLE_COLOR
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


----------------------------------------------------------------------------------------


-- A collection of four particles
SmallParticleCluster = {}

function SmallParticleCluster:new(o)
    o.parent = self
    setmetatable(o, self)
    self.__index = self
    return o
end

function SmallParticleCluster:populate(origin)
    self.position = origin
    self.particles = {}

    for i=0,3 do
        local color = DARK_PARTICLE_COLOR

        if i % 2 == 1 then
            color = LIGHT_PARTICLE_COLOR
        end

        table.insert(self.particles, SingleParticle:new{ color = color })
    end 
end

function SmallParticleCluster:render(context)
    if self.rotation == nil then 
        self.rotation = 0
    end

    local interval = TAU / 4
    local distance = PARTICLE_RADIUS * 1.15

    for i=1,4 do
        local particle = self.particles[i]
        local angle = self.rotation + interval * (i - 1)

        particle.position = {
            x = self.position.x + distance * math.cos(angle),
            y = self.position.y + distance * math.sin(angle)
        }

        particle:render(context)
    end
end

function SmallParticleCluster:rotate(amount) 
    if self.rotation == nil then
        self.rotation = 0
    end

    self.rotation = self.rotation + amount

    if self.rotation >= TAU then
        self.rotation = 0
    end
end

function SmallParticleCluster:move_to(d, x, y)
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

function SmallParticleCluster:move(x, y)
    self.position.x = self.position.x + x
    self.position.y = self.position.y + y
end


----------------------------------------------------------------------------------------


ParticleCluster = {}

function ParticleCluster:new(o)
    o.parent = self
    setmetatable(o, self)
    self.__index = self
    return o
end

function ParticleCluster:populate(cluster_radius)
    self.particle_meta = {}
    self.particles = {}

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

function ParticleCluster:update(delta)
    self.expelled_particles = self.expelled_particles or {}

    for i=1,#self.expelled_particles do
        local particle = self.expelled_particles[i]

        particle:rotate(delta * 2 * particle.rotation_factor)

        if particle.moving then
            particle.moving = not particle:move_to(
                delta,
                particle.target.x,
                particle.target.y
            )
        end
    end
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

    for i=1,#self.expelled_particles do
        self.expelled_particles[i]:render(context)
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

function ParticleCluster:expel_particles(amount)
    self.expelled_particles = self.expelled_particles or {}

    for i=1,amount do
        local small_particle = SmallParticleCluster:new{
            target = {
                x = math.random(PARTICLE_SPREAD_PADDING, SCREEN_SIZE - PARTICLE_SPREAD_PADDING),
                y = math.random(PARTICLE_SPREAD_PADDING, SCREEN_SIZE - PARTICLE_SPREAD_PADDING)
            },
            move_speed = self.move_speed * 2.5,
            moving = true,
            attached_to_player = false,
            rotation_factor = 1 + math.random()
        }

        small_particle:populate({
            x = self.position.x,
            y = self.position.y
        })

        table.insert(self.expelled_particles, small_particle)
    end
end
