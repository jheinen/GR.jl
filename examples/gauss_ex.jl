using GR
using LaTeXStrings

𝒩(μ, σ) = 1 / (σ * √(2π)) * exp.(-0.5 * ((x .- μ) / σ) .^ 2)

x = LinRange(-5, 5, 500);
y = hcat(𝒩(0, √0.2), 𝒩(0, √1), 𝒩(0, √5), 𝒩(-2, √0.5));

plot(x, y, xlabel=L"\mathcal{X}", ylabel=L"\mathcal{N}(\mu,\,\sigma^{2})", title=L"\frac{1}{\sigma\sqrt{2\pi}} e^{-\frac{1}{2} \left({\frac{x-\mu}{\sigma}}\right)^2}", labels=(L"\mu=0, \sigma^2=0.2", L"\mu=0, \sigma^2=1", L"\mu=0, \sigma^2=5", L"\mu={-2}, \sigma^2=0.5"), xlim=(-5.2, 5.2), ylim=(-0.05, 1.05), linewidth=3)
