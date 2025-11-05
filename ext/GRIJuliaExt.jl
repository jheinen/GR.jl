module GRIJuliaExt

import GR
import IJulia

function __init__()
    if @ccall(jl_generating_output()::Cint) == 0
        GR._ijulia_loaded = true
    end
end

end
