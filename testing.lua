Point = {x = 0, y = 0}
function Point:create (o)
  o.parent = self
  setmetatable(o, self)
  self.__index = self
  return o
end

function Point:move (p)
  self.x = self.x + p.x
  self.y = self.y + p.y
end

--
-- creating points
--
p1 = Point:create{x = 10, y = 20}
p2 = Point:create{x = 10}  -- y will be inherited until it is set

--
-- example of a method invocation
--

print(p1.x)
p1:move(p2)
print(p1.x)
