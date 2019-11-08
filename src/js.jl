module js

import GR

pxwidth = 640
pxheight = 480

@static if VERSION < v"0.7.0-DEV.4762"
    macro cfunction(f, rt, tup)
        :(Base.cfunction($(esc(f)), $(esc(rt)), Tuple{$(esc(tup))...}))
    end
end

id_count = 0
js_running = false
dispid = 0


mutable struct JSTermWidget
    identifier::Int
    width::Int
    height::Int
    display::Int
    visible::Bool
end


function inject_js()
  global comm
  comm = nothing
  _js_fallback = "https://gr-framework.org/downloads/gr-latest.js"
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
        <script type="text/javascript">
          """, _gr_js, """
          runJsterm();
        </script>
      """)))
  end
end


function JSTermWidget(id::Int, width::Int, height::Int, display::Int)
  global id_count, js_running
  if GR.isijulia()
    id_count += 1
    if !js_running
      inject_js()
      js_running = true
    end
    JSTermWidget(id, width, height, display, false)
  else
    error("JSTermWidget is only available in IJulia environments")
  end
end

comm = nothing

evthandler = Dict()
global_evthandler = nothing


function register_evthandler(f::Function, device, port)
  global evthandler
  if GR.isijulia()
    send_command(Dict("command" => "enable_events"), "cmd", string(device, port))
    evthandler[string(device, port)] = f
  else
    error("register_evthandler is only available in IJulia environments")
  end
end

function unregister_evthandler(device, port)
  global evthandler
  if GR.isijulia()
    if global_evthandler === nothing
      send_command(Dict("command" => "disable_events"), "cmd", string(device, port))
    end
    evthandler[string(device, port)] = nothing
  else
    error("unregister_evthandler is only available in IJulia environments")
  end
end

function register_evthandler(f::Function)
  global global_evthandler
  if GR.isijulia()
    send_command(Dict("command" => "enable_events"), "cmd", nothing)
    global_evthandler = f
  else
    error("register_evthandler is only available in IJulia environments")
  end
end

function unregister_evthandler()
  global global_evthandler, evthandler
  if GR.isijulia()
    send_command(Dict("command" => "disable_events"), "cmd", nothing)
    for key in keys(evthandler)
      if evthandler[key] !== nothing
        send_command(Dict("command" => "enable_events"), "cmd", key)
      end
    end
    global_evthandler = nothing
  else
    error("unregister_evthandler is only available in IJulia environments")
  end
end

function send_command(msg, msgtype, id=nothing)
  global comm
  if GR.isijulia()
    if comm === nothing
      error("JSTerm comm not initialized.")
    else
      if id !== nothing
        Main.IJulia.send_comm(comm, merge(msg, Dict("type" => msgtype, "id" => id)))
      else
        Main.IJulia.send_comm(comm, merge(msg, Dict("type" => msgtype)))
      end
    end
  else
    error("send_command is only available in IJulia environments")
  end
end

function send_evt(msg, device, port)
  if GR.isijulia()
    send_command(msg, "evt", string(device, port))
  else
    error("send_evt is only available in IJulia environments")
  end
end

function send_evt(msg, identifier)
  if GR.isijulia()
    send_command(msg, "evt", identifier)
  else
    error("send_evt is only available in IJulia environments")
  end
end

function disable_jseventhandling(device, port)
  if GR.isijulia()
    send_command(Dict("command" => "disable_jseventhandling"), "cmd", string(device, port))
  else
    error("disable_jseventhandling is only available in IJulia environments")
  end
end

function enable_jseventhandling(device, port)
  if GR.isijulia()
    send_command(Dict("command" => "enable_jseventhandling"), "cmd", string(device, port))
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
  if GR.isijulia()
    send_command(Dict("command" => "enable_jseventhandling"), "cmd", nothing)
  else
    Main.IJulia.send_comm(comm, Dict("json" => f, "type" => "evt"))
    error("enable_jseventhandling is only available in IJulia environments")
  end
end

function comm_msg_callback(msg)
  data = msg.content["data"]
  if haskey(data, "type")
    if data["type"] == "save"
      display(HTML(string("<div style=\"display:none;\" id=\"jsterm-data-", data["content"]["id"], "\" class=\"jsterm-data\">", data["content"]["data"], "</div>")))
    elseif data["type"] == "evt"
      global_evthandler(data["content"])
      if haskey(evthandler, data["id"]) && evthandler[data["id"]] !== nothing
        evthandler[data["id"]](data["content"])
      end
    end
  end
end

function jsterm_send(data::String)
  global js_running, draw_end_condition, comm, dispid
  if GR.isijulia()
    if comm === nothing
      comm = Main.IJulia.Comm("jsterm_comm")
      comm.on_close = function comm_close_callback(msg)
        global js_running
        js_running = false
      end
      comm.on_msg = comm_msg_callback
    end
    display(HTML(string("<div id=\"jsterm-display-", dispid, "\"><div id=\"jsterm-msg-", dispid, "\">Processing Input</div>")))
    Main.IJulia.send_comm(comm, Dict("json" => data, "type"=>"draw", "display"=>dispid))
    dispid += 1
  else
    error("jsterm_send is only available in IJulia environments")
  end
end

function recv(name::Cstring, id::Int32, msg::Cstring)
    # receives string from C and sends it to JS via Comm
    global js_running, draw_end_condition
    if !js_running
      inject_js()
      js_running = true
    end
    jsterm_send(unsafe_string(msg))
    return convert(Int32, 1)
end

function send(name::Cstring, id::Int32)
    # Dummy function, not in use
    return convert(Cstring, "String")
end

jswidgets = nothing
send_c = nothing
recv_c = nothing

function initjs()
    global jswidgets, send_c, recv_c

    jswidgets = Dict{Int32, JSTermWidget}()
    send_c = @cfunction(send, Cstring, (Cstring, Int32))
    recv_c = @cfunction(recv, Int32, (Cstring, Int32, Cstring))
    send_c, recv_c
end

end # module
