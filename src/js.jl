module js

import GR

const init = Ref(false)

const jssource = Ref("https://gr-framework.org/downloads/gr-0.73.14.js")

function get_jsterm()
  if GR.isijulia()
    display(HTML(string("""
      <script type="text/javascript">
        if (typeof JSTerm === "undefined" && document.getElementById('jstermImport') == null) {
          let jstermScript = document.createElement("script");
          jstermScript.setAttribute("src", \"""", jssource[], """\");
          jstermScript.setAttribute("type", "text/javascript")
          jstermScript.setAttribute("id", "jstermImport")
          document.body.appendChild(jstermScript);
        }
      </script>
    """)))
    return
  end
  return HTML(string("""<script type="text/javascript" src=" """, jssource[], """ "></script>"""))
end

function initjs()
    if !init[]
      init[] = true

      if haskey(ENV, "GR_JS")
        jssource[] = ENV["GR_JS"]
      elseif occursin(".post", GR.version())
        jssource[] = "https://gr-framework.org/downloads/gr-latest.js"
      end
    end
end

precompile(initjs, ())

end # module
