using GR
using SpecialFunctions

x = 0:0.1:20
j0, j1, j2, j3 = [besselj.(order, x) for order in 0:3]

plot(x, j0, x, j1, x, j2, x, j3,
     labels=["J_0", "J_1", "J_2", "J_3"], location=11)
