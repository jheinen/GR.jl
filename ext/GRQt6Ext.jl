module GRQt6Ext

import GR

if isdefined(Base, :get_extension) 
  import GRQt6_jll
else 
  import ..GRQt6_jll
end

function __init__()
  grdir = GR.GRPreferences.grdir[]
  if !isfile(GR.GRPreferences.gksqt_path(grdir))
    GR.GRPreferences.copy_tree(GRQt6_jll.artifact_dir, grdir)
    if Sys.iswindows()
      GR.GRPreferences.copy_tree(GRQt6_jll.Qt6Base_jll.artifact_dir, grdir)
    end
  end
  libpath_env = GRQt6_jll.JLLWrappers.LIBPATH_env
  libenv = filter(x -> startswith(x, libpath_env), GRQt6_jll.gksqt().env)[1]
  GR.GRPreferences.libpath[] = replace(libenv, libpath_env*"=" => "")
  GR.GRPreferences.gksqt[] = GRQt6_jll.gksqt_path
  GR.GRPreferences.grplot[] = GRQt6_jll.grplot_path
end

end