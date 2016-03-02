using GR

x = linspace(0,20,200)
for order in 0:3
  plot(x, besselj(order, x))
  hold(true)
end
legend("J_0", "J_1", "J_2", "J_3")
