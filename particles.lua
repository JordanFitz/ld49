require "ripple"

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

    context.fill_style(self.color)
    context.fill()
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

    -- so that the particle cluster doesn't look uniform
    shuffle(self.particle_meta)
end

function ParticleCluster:update(delta, player)
    if self.ripple ~= nil then
        self.ripple:update(delta)

        if self.ripple.done then
            self.ripple = nil
        end
    end

    self.expelled_particles = self.expelled_particles or {}

    if player.attached_particle_rotation == nil then
        player.attached_particle_rotation = 0
    end

    player.attached_particle_rotation =
        player.attached_particle_rotation +
        ATTACHED_PARTICLE_ROTATION_SPEED * delta

    self.player_attached_particles = self.player_attached_particles or {}

    local distance_to_player = distance(player.position, self.position)
    local min_distance = PARTICLE_ROTATION_RADIUS*1.2

    for i=1,#self.expelled_particles do
        local particle = self.expelled_particles[i]

        particle:rotate(delta * 2 * particle.rotation_factor)

        if not particle.attached_to_player then
            if distance(particle.position, player.position) <= min_distance then
                particle.attached_to_player = true
                particle.moving = false
                table.insert(self.player_attached_particles, particle)
            end

            if particle.moving then
                particle.moving = not particle:move_to(
                    delta,
                    particle.target.x,
                    particle.target.y
                )
            end
        end

    end

    local attached_particle_interval = TAU / #self.player_attached_particles

    for i=1,#self.player_attached_particles do
        local particle = self.player_attached_particles[i]
        local angle =  player.attached_particle_rotation + attached_particle_interval * (i - 1)

        particle.position.x =
            player.position.x + PARTICLE_ROTATION_RADIUS * math.cos(angle)

        particle.position.y =
            player.position.y + PARTICLE_ROTATION_RADIUS * math.sin(angle)

        if distance_to_player < min_distance then
            particle.repossessed = true
        end
    end

    if #self.player_attached_particles == #self.expelled_particles then
        if distance_to_player < min_distance then
            self.moving = true
            self.target = random_location()

            self.player_attached_particles = {}
            self.expelled_particles = {}
        end
    end
end

function ParticleCluster:render(context)
    if self.ripple ~= nil then
        self.ripple:render(context)
    end

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
        local particle = self.expelled_particles[i]
        if not particle.repossessed then
            particle:render(context)
        end
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
            target = random_location(),
            move_speed = self.move_speed * 2.5,
            moving = true,
            attached_to_player = false,
            rotation_factor = 1 + math.random(),
            repossessed = false
        }

        small_particle:populate({
            x = self.position.x,
            y = self.position.y
        })

        table.insert(self.expelled_particles, small_particle)
    end

    self.ripple = Ripple:new{
        origin = {
            x = self.position.x,
            y = self.position.y
        },
        circles = {},
        done = false,
        radius = 0,
        last_radius = 0,
        generating_circles = true
    }
end
