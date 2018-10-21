using GR
import SpecialFunctions

x = 0:0.1:20
for order in 0:3
  plot(x, SpecialFunctions.besselj.(order, x))
  hold(true)
end
legend("J_0", "J_1", "J_2", "J_3")
