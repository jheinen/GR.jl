module GRQt5Ext

import GR
import JLLPrefixes

if isdefined(Base, :get_extension) 
  import GRQt5_jll
else 
  import ..GRQt5_jll
end

function __init__()
  grdir = GR.GRPreferences.grdir[]
  if !isfile(GR.GRPreferences.gksqt_path(grdir))
    JLLPrefixes.deploy_artifact_paths(grdir, [GRQt5_jll.artifact_dir])
  end
  pathsep = GRQt5_jll.JLLWrappers.pathsep
  existing_paths = split(GR.GRPreferences.libpath[], pathsep)
  append!(existing_paths, GRQt5_jll.LIBPATH_list)
  unique!(existing_paths)
  GR.GRPreferences.libpath[] = join(existing_paths, pathsep)
  GR.GRPreferences.gksqt[] = GR.GRPreferences.gksqt_path(grdir)
  GR.GRPreferences.grplot[] = GRQt5_jll.grplot_path
end

end