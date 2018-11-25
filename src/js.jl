module js

import GR

id_count = 0
js_running = false

mutable struct JSTermWidget
    identifier::String
end

function inject_js()
  _js_fallback = "https://gr-framework.org/downloads/gr-latest.js"
  _gr_js = if isfile(joinpath(ENV["GRDIR"], "lib", "gr.js"))
    _gr_js = try
      _gr_js = open(joinpath(ENV["GRDIR"], "lib", "gr.js")) do f
        _gr_js = read(f, String)
        _gr_js = string(_gr_js, "let ready = true;")
        _gr_js
      end
    catch e
      nothing
    end
    _gr_js
  end
  _jsterm = """/* jshint esversion: 6 */
  /*eslint no-console: ["error", { allow: ["warn"] }] */
  /*eslint no-unused-vars: ["error", { "varsIgnorePattern": "^_" }]*/
  (function() {
      if (typeof grJSTermRunning === 'undefined') {
          let onready = [];
          let gr = [];
          let args = [];

          function saveLoad(url, callback, maxtime) {
              let script = document.createElement('script');
              script.onload = function() {
                  callback();
              };
              script.onerror = function() {
                  console.error(url + ' can not be loaded.');
              };
              script.src = url;
              document.head.appendChild(script);
              setTimeout(function() {
                  if (!grJstermReady) {
                      console.error(url + ' can not be loaded.');
                  }
              }, maxtime);
          }

          function jsLoaded() {
              grJstermReady = true;
              for (let i = 0; i < onready.length; i++) {
                  onready[i]();
              }
              onready = [];
          }

          function draw(msg) {
              console.log('Got a message');
              if (!grJstermReady) {
                  onready.push(function() {
                      return draw(msg);
                  });
              } else if (!GR.is_ready) {
                  GR.ready(function() {
                      return draw(msg);
                  });
              } else {
                  console.log('Drawing!');
                  if (typeof gr['jsterm-' + msg.content.data.canvasid] === 'undefined') {
                      gr['jsterm-' + msg.content.data.canvasid] = new GR('jsterm-' + msg.content.data.canvasid);
                  }
                  gr['jsterm-' + msg.content.data.canvasid].select_canvas();
                  if (!args.hasOwnProperty('jsterm-' + msg.content.data.canvasid) || typeof args['jsterm-' + msg.content.data.canvasid] === 'undefined') {
                      args['jsterm-' + msg.content.data.canvasid] = gr['jsterm-' + msg.content.data.canvasid].newmeta();
                  }
                  gr['jsterm-' + msg.content.data.canvasid].readmeta(args['jsterm-' + msg.content.data.canvasid], msg.content.data.json);
                  gr['jsterm-' + msg.content.data.canvasid].clearws();
                  gr['jsterm-' + msg.content.data.canvasid].plotmeta(args['jsterm-' + msg.content.data.canvasid]);
              }
          }
          
          function register_comm(kernel) {
              kernel.comm_manager.register_target('jsterm_comm', function(comm) {
                  comm.on_msg(function(msg) {
                      draw(msg);
                      comm.close();
                  });
                  comm.on_close(function() {
                      console.log('Comm closed');
                  });
                  window.addEventListener('beforeunload', function (e) {
                    // e.preventDefault();
                    comm.close();
                  });
              });
          }

          function onLoad() {
              Jupyter.notebook.events.on('execution_request.Kernel', function() {
                  for (var key in gr) {
                      if (args.hasOwnProperty(key)) {
                          gr[key].deletemeta(args[key])
                      }
                  }
                  gr = [];
                  args = [];
              });
              let kernel = Jupyter.notebook.kernel;
              if (typeof kernel === 'undefined' || kernel == null) {
                  console.error('JSTerm: No kernel detected');
                  return;
              }
              register_comm(kernel);
              Jupyter.notebook.events.on('kernel_ready.Kernel', function() {
                  kernel = IPython.notebook.kernel;
                  register_comm(kernel);
              });
          }
          onLoad();
      }
  })();
  var grJSTermRunning = true;"""
  if _gr_js === nothing
      _gr_js = string("""
        saveLoad('""", _js_fallback, """', jsLoaded, 10000);
        var grJstermReady = false;
      """)
  else
    _gr_js = string(_gr_js, "var grJstermReady = true;")
  end
  display(HTML(string("""
    <script type="text/javascript">
      """, _gr_js, """
      """, _jsterm, """
    </script>
  """)))
end

function JSTermWidget(name::String, id::Int64)
  global id_count, js_running
  if GR.isijulia()
    print(js_running)
    id_count += 1
    if !js_running
      inject_js()
      js_running = true
    end
    JSTermWidget(string(name, id))
  else
    error("JSTermWidget is only available in IJulia environments")
  end
end

function jsterm_display(widget::JSTermWidget)
  if GR.isijulia()
    display(HTML(string("<canvas id=\"jsterm-", widget.identifier, "\" width=\"500\" height=\"500\"></canvas>")))
  else
    error("jsterm_display is only available in IJulia environments")
  end
end

function jsterm_send(widget::JSTermWidget, data::String)
  global js_running
  if GR.isijulia()
    comm = Main.IJulia.Comm("jsterm_comm")
    Main.IJulia.send_comm(comm, Dict("json" => data, "canvasid" => widget.identifier))
  else
    error("jsterm_send is only available in IJulia environments")
  end
end

function recv(name::Cstring, id::Int64, msg::Cstring)
    # receives string from C and sends it to JS via Comm
    _name = unsafe_string(name)
    if haskey(jswidgets, string(_name, id))
        widget = jswidgets[string(_name, id)]
    else
        widget = JSTermWidget(_name, id)
        jswidgets[string(_name, id)] = widget
        jsterm_display(widget)
    end
    jsterm_send(widget, unsafe_string(msg))
    return convert(Int32, 1)
end

function send(name::Cstring, id::Int64)
    # Dummy function, not in use
    print(string("send", name, id, "\n"))
    return convert(Cstring, "String")
end

jswidgets = nothing
recv_c = nothing
send_c = nothing

function initjs()
    global jswidgets, recv_c, send_c

    jswidgets = Dict{String, JSTermWidget}()
    recv_c = @cfunction(recv, Int32, (Cstring, Int64, Cstring))
    send_c = @cfunction(send, Cstring, (Cstring, Int64))
end

end # module
