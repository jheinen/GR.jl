# Julia package for GR, a visualization framework

This module provides a Julia interface to the
[GR framework](http://gr-framework.org/).

You will need to have the GR framework installed on your
machine in order to use GR. Clone the main source using:

    git clone https://github.com/jheinen/gr

and build and install as usual with:

    cd gr
    make
    make install
    make clean

This will install the GR framework into the directory ``/usr/local/gr``.

Once the GR framework is installed you can use `Pkg.add("GR")`
in Julia to install the GR module. You are now ready tu use GR.

In Julia simply type `using GR` and begin calling functions
in the [GR framework](http://gr-framework.org/gr.html) API.

