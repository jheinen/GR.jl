using GR

# Simple particle simulation

const N = 300                   # number of particles
M = 0.05 * ones(Float64, N)     # masses
const S = 0.04                  # size of particles

function step(dt, p, v)
  # update positions
  p[:,:] += dt * v[:,:]

  # find pairs of particles undergoing a collision
  for i in 1:N
    for j in i+1:N
      dx = p[i,1] - p[j,1]
      dy = p[i,2] - p[j,2]
      d = sqrt(dx*dx + dy*dy)

      if d < 2*S
        # relative location & velocity vectors
        r_rel = p[i] - p[j]
        v_rel = v[i] - v[j]

        # momentum vector of the center of mass
        v_cm = (M[i] * v[i] + M[j] * v[j]) / (M[i] + M[j])

        # collisions of spheres reflect v_rel over r_rel
        rr_rel = dot(r_rel, r_rel)
        vr_rel = dot(v_rel, r_rel)
        v_rel = 2 * r_rel * vr_rel / rr_rel - v_rel

        # assign new velocities
        v[i] = v_cm + v_rel * M[j] / (M[i] + M[j])
        v[j] = v_cm - v_rel * M[i] / (M[i] + M[j])
      end
    end
  end

  # check for crossing boundary
  for i in 1:N
    if p[i,1] < -2 + S
      p[i,1] = -2 + S
      v[i,1] *= -1
    elseif p[i,1] > 2 - S
      p[i,1] = 2 - S
      v[i,1] *= -1
    end
    if p[i,2] < -2 + S
      p[i,2] = -2 + S
      v[i,2] *= -1
    elseif p[i,2] > 2 - S
      p[i,2] = 2 - S
      v[i,2] *= -1
    end
  end

  return p, v
end

setwindow(-2, 2, -2, 2)
setviewport(0, 1, 0, 1)
setmarkertype(GR.MARKERTYPE_SOLID_CIRCLE)
setmarkersize(1.0)

n = 0
t = 0.0

p = (rand(N,2) - 0.5) * (4-2*S)     # initial positions
v = rand(N,2) - 0.5                 # initial velocities

const dt = 1.0 / 30

while t < 3

  start = tic()
  p, v = step(dt, p, v)

  clearws()
  setmarkercolorind(75)
  polymarker(p[:,1], p[:,2])

  if n > 0
    text(0.01, 0.95, @sprintf("%10s: %4d fps", "Julia", round(n / t)))
  end
  updatews()

  n += 1
  t += 1.0 / (toq() * 1000000)

end
