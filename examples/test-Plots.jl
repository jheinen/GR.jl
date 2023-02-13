using Plots, Test

@info("Interactive tests")
Plots.test_examples(:gr, disp=true)

@info("Figure output tests")
prefix = tempname()
@time for i ∈ 1:length(Plots._examples)
  i ∈ Plots._backend_skips[:gr] && continue  # skip unsupported examples
  Plots._examples[i].imports ≡ nothing || continue  # skip examples requiring optional test deps
  pl = Plots.test_examples(:gr, i; disp = false)
  for ext in (".png", ".pdf", ".svg")
    fn = string(prefix, i, ext)
    Plots.savefig(pl, fn)
    @test filesize(fn) > 1_000
  end
end
