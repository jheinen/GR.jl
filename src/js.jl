module js

import GR
import UUIDs

pxwidth = 640
pxheight = 480

id_count = 0
js_running = false
checking_js = false
send_on_connect = Dict()


mutable struct JSTermWidget
    identifier::Int
    width::Int
    height::Int
    disp::Int
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
        <script type="text/javascript" id="jsterm-javascript">
          if (typeof jsterm === 'undefined') {
              """, _gr_js, """
          }
        </script>
      """)))
  end
end

check_comm = nothing

function check_js()
    global js_running, checking_js
    if !checking_js
        checking_js = true
        @eval function Main.IJulia.register_comm(c::Main.IJulia.Comm, data)
            global js_running, send_on_connect, checking_js, comm
            if data.content["target_name"] == "check_comm"
                testcomm = c
                testcomm.on_msg = function(msg)
                    if msg.content["data"]["inject_js"]
                        inject_js()
                    end
                end
                testcomm.on_close = function(msg)
                    d = Dict("text/html"=>string(""))
                    transient = Dict("display_id"=>"jsterm_check")
                    Main.IJulia.send_ipython(Main.IJulia.publish[], Main.IJulia.msg_pub(Main.IJulia.execute_msg, "update_display_data", Dict("data"=>d, "metadata"=>Dict(), "transient"=>transient)))
                    checking_js = false
                end
            elseif data.content["target_name"] == "jsterm_comm"
                comm = c
                js_running = true
                comm.on_close = function comm_close_callback(msg)
                  global js_running, comm
                  js_running = false
                  comm = nothing
                end
                comm.on_msg = comm_msg_callback
                for disp in keys(send_on_connect)
                    jsterm_send(send_on_connect[disp], disp)
                end
                send_on_connect = Dict()
            end
        end
        d = Dict("text/html"=>string("""
          <script type="text/javascript">
            var check_comm = Jupyter.notebook.kernel.comm_manager.new_comm('check_comm');
            check_comm.send({"inject_js": document.getElementById('jsterm-javascript') === null});
            if (typeof JSTerm !== 'undefined') {
                if (typeof jsterm === 'undefined') {
                    jsterm = new JSTerm();
                    console.log('jsterm created');
                }
                jsterm.registerComm();
            }
            check_comm.close();
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
      check_js()
    end
    JSTermWidget(id, width, height, disp, false)
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
      d = Dict("text/html"=>string("<div style=\"display: none;\" class=\"jsterm-data-widget\">", data["content"]["data"]["widget_data"], "</div>"))
      transient = Dict("display_id"=>string("save_display_", data["display_id"]))
      Main.IJulia.send_ipython(Main.IJulia.publish[], Main.IJulia.msg_pub(Main.IJulia.execute_msg, "update_display_data", Dict("data"=>d, "metadata"=>Dict(), "transient"=>transient)))
    elseif data["type"] == "evt"
      global_evthandler(data["content"])
      if haskey(evthandler, data["id"]) && evthandler[data["id"]] !== nothing
        evthandler[data["id"]](data["content"])
      end
    end
  end
end

function jsterm_send(data::String, disp)
  global js_running, draw_end_condition, comm
  if GR.isijulia()
    Main.IJulia.send_comm(comm, Dict("json" => data, "type"=>"draw", "display"=>disp))
  else
    error("jsterm_send is only available in IJulia environments")
  end
end

function recv(name::Cstring, id::Int32, msg::Cstring)
    # receives string from C and sends it to JS via Comm
    global js_running, draw_end_condition, send_on_connect

    disp = string(UUIDs.uuid4());

    d = Dict("text/html"=>"")
    transient = Dict("display_id"=>string("save_display_", disp))
    Main.IJulia.send_ipython(Main.IJulia.publish[], Main.IJulia.msg_pub(Main.IJulia.execute_msg, "display_data", Dict("data"=>d, "metadata"=>Dict(), "transient"=>transient)))
    display(HTML(string("<div style=\"display: none;\" id=\"jsterm-display-", disp, "\">")))
    if !js_running
      check_js()
      send_on_connect[disp] = unsafe_string(msg)
    else
        jsterm_send(unsafe_string(msg), disp)
    end
    return convert(Int32, 1)
end

function send(name::Cstring, id::Int32)
    # Dummy function, not in use
    return convert(Cstring, "String")
end

jswidgets = nothing
send_c = nothing
recv_c = nothing
init = false

function initjs()
    global jswidgets, send_c, recv_c, init

    if !init && GR.isijulia()
        init = true
        jswidgets = Dict{Int32, JSTermWidget}()
        send_c = @cfunction(send, Cstring, (Cstring, Int32))
        recv_c = @cfunction(recv, Int32, (Cstring, Int32, Cstring))
        check_js()
    end
    send_c, recv_c
end

end # module
