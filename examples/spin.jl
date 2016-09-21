import GR
const GR3 = GR.gr3

rate = 100

μ0 = [0.03, 0., 0.09]
Β = [0., 0., 0.8]
γ = 2.0
η = 0.1
ΔT = 0.001

function calcualate_magnetic_moment()
  μ = μ0
  while true
    produce(μ)
    P = - γ * μ × Β            # precession
    G = η * (μ / norm(μ)) × P  # Gilbert damping
    dμ = (P + G) * ΔT
    if norm(dμ) < 1e-6
      return
    end
    μ += dμ
  end
end

function calculate_cone_length(radius, cone_angle)
  2 * radius / tand(cone_angle)
end

function drawarrowmesh(start, end_, color, radius, cone_angle=20)
  direction = end_ - start
  length = norm(direction)
  cone_length = calculate_cone_length(radius, cone_angle)
  cylinder_length = length - cone_length
  direction /= length
  cone_start = start + cylinder_length * direction
  if cylinder_length > 0
    GR3.drawcylindermesh(1, start, direction, color, [radius], [cylinder_length])
  end
  GR3.drawconemesh(1, cone_start, direction, color, [2 * radius], [cone_length])
end

t = Task(calcualate_magnetic_moment)
i = 0

GR.setviewport(0, 1, 0, 1)
GR3.setbackgroundcolor(1, 1, 1, 1)

while !istaskdone(t)
  magmom = consume(t)

  i += 1
  if i % rate != 0
    continue
  end

  point = 5 * magmom / norm(magmom)

  GR.clearws()
  GR3.clear()
  GR3.drawspheremesh(1, [0, 0, 0], [0, 0.75, 0.75], [1])
  drawarrowmesh([0, 0, 0], point, [1, 0, 0], 0.1)
  GR3.drawspheremesh(1, point, [0, 1, 0], [0.2])
  GR3.cameralookat(10, 0, 10, 0, 0, 0, 0, 0, 1)
  GR3.drawimage(0, 1, 0, 1, 500, 500, GR3.DRAWABLE_GKS)
  GR.updatews()
end
