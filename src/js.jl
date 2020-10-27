module js

import GR

pxwidth = 640
pxheight = 480

id_count = 0
js_running = false
checking_js = false
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
  global wss, port

  wss = nothing
  _gr_js = if isfile(joinpath(ENV["GRDIR"], "lib", "gr.js"))
    _gr_js = try
      _gr_js = open(joinpath(ENV["GRDIR"], "lib", "gr.js")) do f
        _gr_js = read(f, String)
        _gr_js
      end
    catch e
      nothing
    end
    _gr_js
  end
  if _gr_js === nothing
      error(string("Unable to open '", joinpath(ENV["GRDIR"], "lib", "gr.js"), "'."))
  else
      display(HTML(string("""
        <script type="text/javascript" id="jsterm-javascript">
          WEB_SOCKET_ADDRESS = 'ws://127.0.0.1:""", port, """';
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
    global js_running, checking_js, port
    if !checking_js
        checking_js = true
        d = Dict("text/html"=>string("""
          <script type="text/javascript">
            WEB_SOCKET_ADDRESS = 'ws://127.0.0.1:""", port, """';
            if (typeof JSTerm !== 'undefined') {
              if (typeof jsterm === 'undefined') {
                jsterm = new JSTerm();
              }
              jsterm.connectWs();
            } else {
              ws = new WebSocket('ws://127.0.0.1:""", port, """');
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
  global id_count, js_running
  if GR.isijulia()
    id_count += 1
    if !js_running
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
    send_command(Dict("command" => "enable_events"), "cmd", id)
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
      send_command(Dict("command" => "disable_events"), "cmd", id)
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
    send_command(Dict("command" => "enable_events"), "cmd", nothing)
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
    send_command(Dict("command" => "disable_events"), "cmd", nothing)
    lock(l) do
      for key in keys(evthandler)
        if evthandler[key] !== nothing
          send_command(Dict("command" => "enable_events"), "cmd", key)
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
  if GR.isijulia()
    if id !== nothing
      m = merge(msg, Dict("type" => msgtype, "id" => id))
    else
      m = merge(msg, Dict("type" => msgtype))
    end
    if !js_running
      conditions["sendonconnect"] = Condition()
      @async check_js()
      wait(conditions["sendonconnect"])
    end
    if ws != nothing
      try
        HTTP.write(ws, Array{UInt8}(JSON.json(m)))
      catch e
        ws = nothing
        js_running = false
      end
    end
  else
    error("send_command is only available in IJulia environments")
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
    send_command(Dict("command" => "disable_jseventhandling"), "cmd", id)
  else
    error("disable_jseventhandling is only available in IJulia environments")
  end
end

function enable_jseventhandling(id)
  if GR.isijulia()
    send_command(Dict("command" => "enable_jseventhandling"), "cmd", id)
  else
    error("enable_jseventhandling is only available in IJulia environments")
  end
end

function disable_jseventhandling()
  if GR.isijulia()
    send_command(Dict("command" => "disable_jseventhandling"), "cmd", nothing)
  else
    error("disable_jseventhandling is only available in IJulia environments")
  end
end

function enable_jseventhandling()
  global ws
  if GR.isijulia()
    send_command(Dict("command" => "enable_jseventhandling"), "cmd", nothing)
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
  send_command(Dict("command" => "settooltip", "html" => tthtml, "data" => ttdata), "cmd", id)
  return nothing
end

pluto_data = Dict()
pluto_disp = ""

function get_pluto_html()
  global pluto_data, pluto_disp, plutoisinit
  str = JSON.json(pluto_data)
  # remove leading and trailing '"'
  str = str[2:lastindex(str)]
  if plutoisinit
    return HTML(string("""
      <div id="jsterm-display-""", pluto_disp, """\">
      </div>
      <script type="text/javascript">
        function defer() {
          if (typeof JSTerm === 'undefined') {
            setTimeout(function() { defer() }, 50);
          } else {
            if (typeof jsterm === "undefined") {
              var jsterm = new JSTerm(true);
            }
            jsterm.draw({
              "json": '""", str, """',
              "display": '""", pluto_disp, """'
            })
          }
        }
        defer();
      </script>
    """))
  else
    return "JSTerm (GR) not initialized. Run `GR.js.init_pluto()` at the end of a codecell"
  end
end

function jsterm_send(data::String, disp)
  global js_running, draw_end_condition, ws, conditions, pluto_data, pluto_disp
  if GR.isijulia()
    if !js_running
      conditions["sendonconnect"] = Condition()
      @async check_js()
      wait(conditions["sendonconnect"])
    end
      if ws != nothing
        try
          conditions[disp] = Condition()
          HTTP.write(ws, Array{UInt8}(JSON.json(Dict("json" => data, "type"=>"draw", "display"=>disp))))
          wait(conditions[disp])
        catch e
          ws = nothing
          js_running = false
        end
      end
  elseif GR.displayname() == "pluto"
    pluto_data = data
    pluto_disp = disp
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
    global js_running, draw_end_condition

    id = string(UUIDs.uuid4());
    jsterm_send(unsafe_string(msg), id)
    return convert(Int32, 1)
end

function send(name::Cstring, id::Int32)
    # Dummy function, not in use
    return convert(Cstring, "String")
end

send_c = nothing
recv_c = nothing
init = false

function ws_cb(webs)
  global comm_msg_callback, ws, js_running, conditions, checking_js
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
        checking_js = false
      elseif data == "js-running"
        d = Dict("text/html"=>string(""))
        transient = Dict("display_id"=>"jsterm_check")
        Main.IJulia.send_ipython(Main.IJulia.publish[], Main.IJulia.msg_pub(Main.IJulia.execute_msg, "update_display_data", Dict("data"=>d, "metadata"=>Dict(), "transient"=>transient)))
        ws = webs
        js_running = true
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
    js_running = false
    @async check_js()
  end
end

plutoisinit = false

function init_pluto(jssource="https://gr-framework.org/downloads/gr-latest.js")
  global plutoisinit
  plutoisinit = true
  return HTML(string("""
    <script type="text/javascript" src=" """, jssource, """ "></script>
  """))
end

function initjs()
    global send_c, recv_c, init, checking_js, port, connect_cond, connected
    if !init
      init = true
      send_c = @cfunction(send, Cstring, (Cstring, Int32))
      recv_c = @cfunction(recv, Int32, (Cstring, Int32, Cstring))
      @eval js begin
        import UUIDs
        import HTTP
        import Sockets
        import JSON
      end
      if GR.isijulia()
        connect_cond = Condition()
        connected = false
        ws_server_task = @async begin
          global port, connect_cond, connected
          #port, server = Sockets.listenany(8081)
          port = 8081
          #server = Sockets.listen(8081)
          #@async HTTP.listen(server=server, verbose=true) do webs
          @async HTTP.WebSockets.listen("0.0.0.0", UInt16(8081)) do webs
            ws_cb(webs)
            #HTTP.WebSockets.upgrade(ws_cb, webs)
          end
          connected = true
          notify(connect_cond)
        end
        if !connected
          wait(connect_cond)
        end
      end
    end
    send_c, recv_c
end

end # module
