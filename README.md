# The GR module for Julia

[![The MIT License](https://img.shields.io/badge/license-MIT-orange.svg?style=flat-square)](http://opensource.org/licenses/MIT)
[![Build Status](https://travis-ci.org/jheinen/GR.jl.svg?branch=master)](https://travis-ci.org/jheinen/GR.jl)
[![GR](http://pkg.julialang.org/badges/GR_0.6.svg)](http://pkg.julialang.org/?pkg=GR&ver=0.6)

[![Join the chat at https://gitter.im/jheinen/GR.jl](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/jheinen/GR.jl?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

This module provides a Julia interface to
[GR](http://gr-framework.org/), a framework for
visualisation applications.

From the Julia REPL an up to date version can be installed with:

    Pkg.add("GR")

The Julia package manager will download and install a pre-compiled
run-time (for your hardware architecture), if the GR software is not
already installed in the recommended locations.

In Julia simply type ``using GR`` and begin calling functions
in the [GR framework](http://gr-framework.org/julia-gr.html) API.

Let's start with a simple example. We generate 10,000 random numbers and
create a histogram. The histogram function automatically chooses an appropriate
number of bins to cover the range of values in x and show the shape of the
underlying distribution.

```julia
using GR
histogram(randn(10000))
```

### Using GR as backend for Plots.jl

``Plots`` is a powerful wrapper around other Julia visualization
"backends", where ``GR`` seems to be one of the favorite ones.
To get an impression how complex visualizations may become
easier with [Plots](https://juliaplots.github.io), take a look at
[these](http://docs.juliaplots.org/latest/examples/gr/)  examples.

``Plots`` is great on its own, but the real power comes from the ecosystem surrounding it. You can find more information
[here](http://docs.juliaplots.org/latest/ecosystem/).

