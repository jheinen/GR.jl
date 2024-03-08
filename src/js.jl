module js

import GR

pxwidth = 640
pxheight = 480

id_count = 0
const js_running = Ref(false)
const checking_js = Ref(false)
const port = Ref(0)
const connected = Ref(false)
const connect_cond = Ref(Condition())
conditions = Dict()
l = ReentrantLock()

mutable struct JSTermWidget
    identifier::Int
    width::Int
    height::Int
    disp::Int
    visible::Bool
end

function inject_js()
  global wss

  wss = nothing
  gr_js_source = joinpath(ENV["GRDIR"], "lib", "gr.js")
  _gr_js = if isfile(gr_js_source)
    _gr_js = try
      _gr_js = open(gr_js_source) do f
        _gr_js = read(f, String)
        _gr_js
      end
    catch e
      nothing
    end
    _gr_js
  end
  if _gr_js === nothing
      error(string("Unable to open '", gr_js_source, "'."))
  else
      display(HTML(string("""
        <script type="text/javascript" id="jsterm-javascript">
          WEB_SOCKET_ADDRESS = 'ws://127.0.0.1:""", port[], """';
          if (typeof jsterm === 'undefined') {
            """, _gr_js, """
            jsterm = new JSTerm();
            jsterm.connectWs();
          }
        </script>
      """)))
  end
end

function check_js()
    if !checking_js[]
        checking_js[] = true
        d = Dict("text/html"=>string("""
          <script type="text/javascript">
            WEB_SOCKET_ADDRESS = 'ws://127.0.0.1:""", port[], """';
            if (typeof JSTerm !== 'undefined') {
              if (typeof jsterm === 'undefined') {
                jsterm = new JSTerm();
              }
              jsterm.connectWs();
            } else {
              ws = new WebSocket('ws://127.0.0.1:""", port[], """');
              ws.onopen = function() {
                ws.send("inject-js");
                ws.close();
              }
            }
          </script>
        """))
        transient = Dict("display_id"=>"jsterm_check")
        Main.IJulia.send_ipython(Main.IJulia.publish[], Main.IJulia.msg_pub(Main.IJulia.execute_msg, "display_data", Dict("data"=>d, "metadata"=>Dict(), "transient"=>transient)))
    end
end


function JSTermWidget(id::Int, width::Int, height::Int, disp::Int)
  global id_count
  if GR.isijulia() && GR.displayname() == "js-server"
    id_count += 1
    if !js_running[]
      @async check_js()
    end
    JSTermWidget(id, width, height, disp, false)
  else
    error("JSTermWidget is only available in IJulia environments")
  end
end

wss = nothing

evthandler = Dict{Int32,Any}()
global_evthandler = nothing


function register_evthandler(f::Function, id)
  global evthandler, l
  if GR.isijulia()
    send_command(Dict("command" => "enable_events"), "request", id)
    lock(l) do
      evthandler[id] = f
    end
  else
    error("register_evthandler is only available in IJulia environments")
  end
end

function unregister_evthandler(id)
  global evthandler, l
  if GR.isijulia()
    if global_evthandler === nothing
      send_command(Dict("command" => "disable_events"), "request", id)
    end
    lock(l) do
      evthandler[id] = nothing
    end
  else
    error("unregister_evthandler is only available in IJulia environments")
  end
end

function register_evthandler(f::Function)
  global global_evthandler, l
  if GR.isijulia()
    send_command(Dict("command" => "enable_events"), "request", nothing)
    lock(l) do
      evthandler[id] = f
    end
  else
    error("register_evthandler is only available in IJulia environments")
  end
end

function unregister_evthandler()
  global global_evthandler, evthandler, l
  if GR.isijulia()
    send_command(Dict("command" => "disable_events"), "request", nothing)
    lock(l) do
      for key in keys(evthandler)
        if evthandler[key] !== nothing
          send_command(Dict("command" => "enable_events"), "request", key)
        end
      end
      evthandler[id] = nothing
    end
  else
    error("unregister_evthandler is only available in IJulia environments")
  end
end

function send_command(msg, msgtype, id=nothing)
  global wss, ws
  if GR.isijulia() && GR.displayname() == "js-server"
    if id !== nothing
      m = merge(msg, Dict("type" => msgtype, "id" => id))
    else
      m = merge(msg, Dict("type" => msgtype))
    end
    if !js_running[]
      conditions["sendonconnect"] = Condition()
      @async check_js()
      wait(conditions["sendonconnect"])
    end
    if ws !== nothing
      try
        HTTP.write(ws, Array{UInt8}(JSON.json(m)))
      catch e
        ws = nothing
        js_running[] = false
      end
    end
  elseif GR.displayname() == "js-server"
    error("'js-server' is only available in IJulia environments.")
  else
    error(str("Display '", GR.displayname(), "' does not support send_command()."))
  end
end

function send_evt(msg, id)
  if GR.isijulia()
    send_command(msg, "evt", id)
  else
    error("send_evt is only available in IJulia environments")
  end
end

function disable_jseventhandling(id)
  if GR.isijulia()
    send_command(Dict("command" => "disable_jseventhandling"), "request", id)
  else
    error("disable_jseventhandling is only available in IJulia environments")
  end
end

function enable_jseventhandling(id)
  if GR.isijulia()
    send_command(Dict("command" => "enable_jseventhandling"), "request", id)
  else
    error("enable_jseventhandling is only available in IJulia environments")
  end
end

function disable_jseventhandling()
  if GR.isijulia()
    send_command(Dict("command" => "disable_jseventhandling"), "request", nothing)
  else
    error("disable_jseventhandling is only available in IJulia environments")
  end
end

function enable_jseventhandling()
  global ws
  if GR.isijulia()
    send_command(Dict("command" => "enable_jseventhandling"), "request", nothing)
  else
    error("enable_jseventhandling is only available in IJulia environments")
  end
end

function comm_msg_callback(msg)
  global conditions, evthandler, l
  data = msg
  if haskey(data, "type")
    if data["type"] == "save"
      d = Dict("text/html"=>string("<script type=\"text/javascript\" class=\"jsterm-data-widget\">", data["content"]["data"]["widget_data"], "</script>"))
      transient = Dict("display_id"=>string("save_display_", data["display_id"]))
      Main.IJulia.send_ipython(Main.IJulia.publish[], Main.IJulia.msg_pub(Main.IJulia.execute_msg, "update_display_data", Dict("data"=>d, "metadata"=>Dict(), "transient"=>transient)))
    elseif data["type"] == "evt"
      lock(l) do
        if haskey(evthandler, data["id"]) && evthandler[data["id"]] !== nothing
          evthandler[data["id"]](data["content"])
        end
      end
    elseif data["type"] == "value"

    elseif data["type"] == "createDisplay"
      d = Dict("text/html"=>"")
      transient = Dict("display_id"=>string("save_display_", data["dispid"]))
      Main.IJulia.send_ipython(Main.IJulia.publish[], Main.IJulia.msg_pub(Main.IJulia.execute_msg, "display_data", Dict("data"=>d, "metadata"=>Dict(), "transient"=>transient)))
      display(HTML(string("<div style=\"display: none;\" id=\"jsterm-display-", data["dispid"], "\">")))
    elseif data["type"] == "ack"
      notify(conditions[data["dispid"]])
    end
  end
end

function settooltip(tthtml, ttdata, id)
  send_command(Dict("command" => "settooltip", "html" => tthtml, "data" => ttdata), "request", id)
  return nothing
end

const pluto_data = Ref("")
const pluto_disp = Ref("")

function get_html()
  outp = string("""
    <div id="jsterm-display-""", pluto_disp[], """\">
    </div>
    <script type="text/javascript">
      if (typeof jsterm === "undefined") {
        var jsterm = null;
      }
      function run_on_start(data, display) {
        if (typeof JSTerm === "undefined") {
          setTimeout(function() {run_on_start(data, display)}, 100);
          return;
        }
        if (jsterm === null) {
          jsterm = new JSTerm(true);
        }
        jsterm.draw({
          "json": data,
          "display": display
        })
      }
      run_on_start('""", pluto_data[], """', '""", pluto_disp[], """');
    </script>
  """)
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
    """, outp)))
    return
  end
  if plutoisinit[]
    return HTML(outp)
  else
    return HTML(string("""<script type="text/javascript" src=" """, jssource[], """ "></script>""", outp))
  end
end

function jsterm_send(data::String, disp)
  global draw_end_condition, ws, conditions
  if GR.isijulia() && GR.displayname() == "js-server"
    if !js_running[]
      conditions["sendonconnect"] = Condition()
      @async check_js()
      wait(conditions["sendonconnect"])
    end
    if ws !== nothing
      try
        conditions[disp] = Condition()
        HTTP.write(ws, Array{UInt8}(JSON.json(Dict("json" => data, "type"=>"draw", "display"=>disp))))
        wait(conditions[disp])
      catch e
        ws = nothing
        js_running[] = false
      end
    end
  elseif GR.displayname() == "pluto" || GR.displayname() == "js"
    pluto_data[] = data
    pluto_disp[] = disp
  else
    error("jsterm_send is only available in IJulia environments and Pluto.jl notebooks")
  end
end

function get_prev_plot_id()
  send_command(Dict("value"=>"prev_id"), "inq")
end

function set_ref_id(id::Int)
  send_command(Dict("id"=>id), "set_ref_id")
end

function recv(name::Cstring, id::Int32, msg::Cstring)
    # receives string from C and sends it to JS via Comm
    global draw_end_condition

    id = string(UUIDs.uuid4());
    jsterm_send(unsafe_string(msg), id)
    return convert(Int32, 1)
end

function send(name::Cstring, id::Int32)
    # Dummy function, not in use
    return convert(Cstring, "String")
end

const send_c = Ref(C_NULL)
const recv_c = Ref(C_NULL)
const init = Ref(false)

function ws_cb(webs)
  global comm_msg_callback, ws, conditions
  check = false
  while !eof(webs)
    data = readavailable(webs)
    if length(data) > 0
      data = String(data)
      if data == "inject-js"
        check = true
        inject_js()
        d = Dict("text/html"=>string(""))
        transient = Dict("display_id"=>"jsterm_check")
        Main.IJulia.send_ipython(Main.IJulia.publish[], Main.IJulia.msg_pub(Main.IJulia.execute_msg, "update_display_data", Dict("data"=>d, "metadata"=>Dict(), "transient"=>transient)))
        checking_js[] = false
      elseif data == "js-running"
        d = Dict("text/html"=>string(""))
        transient = Dict("display_id"=>"jsterm_check")
        Main.IJulia.send_ipython(Main.IJulia.publish[], Main.IJulia.msg_pub(Main.IJulia.execute_msg, "update_display_data", Dict("data"=>d, "metadata"=>Dict(), "transient"=>transient)))
        ws = webs
        js_running[] = true
        if haskey(conditions, "sendonconnect")
          notify(conditions["sendonconnect"])
        end
      else
        comm_msg_callback(JSON.parse(data))
      end
    end
  end
  if !check
    ws = nothing
    js_running[] = false
    @async check_js()
  end
end

const plutoisinit = Ref(false)
const jssource = Ref("https://gr-framework.org/downloads/gr-0.73.3.js")

function init_pluto(source=jssource[]::String)
  plutoisinit[] = true
  return HTML(string("""
    <script type="text/javascript" src=" """, source, """ "></script>
  """))
end

function initjs()
    if !init[]
      init[] = true
      send_c[] = @cfunction(send, Cstring, (Cstring, Int32))
      recv_c[] = @cfunction(recv, Int32, (Cstring, Int32, Cstring))
      @eval js begin
        import UUIDs
        import JSON
      end
      if haskey(ENV, "GR_JS")
        jssource[] = ENV["GR_JS"]
      elseif occursin(".post", GR.version())
        jssource[] = "https://gr-framework.org/downloads/gr-latest.js"
      end
      if GR.displayname() == "js-server"
        if GR.isijulia()
          @eval js begin
            import HTTP
            import Sockets
          end
          connect_cond[] = Condition()
          connected[] = false
          ws_server_task = @async begin
            port[], server = Sockets.listenany(8081)
            @async HTTP.listen(server=server) do webs
              HTTP.WebSockets.upgrade(ws_cb, webs)
            end
            connected[] = true
            notify(connect_cond[])
          end
          if !connected[]
            wait(connect_cond[])
          end
        else
          error("'js-server' is only available in IJulia environments.")
        end
      end
    end
    send_c[], recv_c[]
end

precompile(initjs, ())

end # module
