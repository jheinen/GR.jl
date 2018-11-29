module js

import GR

@static if VERSION < v"0.7.0-DEV.4762"
    macro cfunction(f, rt, tup)
        :(Base.cfunction($(esc(f)), $(esc(rt)), Tuple{$(esc(tup))...}))
    end
end

id_count = 0
js_running = false

mutable struct JSTermWidget
    identifier::String
    visible::Bool
end

function inject_js()
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
  _jsterm = """/* jshint esversion: 6 */
  /*eslint no-console: ["error", { allow: ["warn"] }] */
  /*eslint no-unused-vars: ["error", { "varsIgnorePattern": "^_" }]*/
    if (typeof grJSTermRunning === 'undefined') {
      function JSTerm() {
        this.onready = [];
        this.gr = [];
        this.args = [];
        this.canvas = [];
        this.comm = undefined;

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
            for (let i = 0; i < this.onready.length; i++) {
                this.onready[i]();
            }
            this.onready = [];
        }

        function canvas_removed(id) {
          this.comm.send({"type":"removed","content":id})
        }

        function draw(msg) {
            if (!grJstermReady) {
                this.onready.push(function() {
                    return draw(msg);
                });
            } else if (!GR.is_ready) {
                GR.ready(function() {
                    return draw(msg);
                });
            } else {
                if (typeof this.canvas['jsterm-' + msg.content.data.canvasid] === 'undefined') {
                  this.canvas['jsterm-' + msg.content.data.canvasid] = document.getElementById('jsterm-' + msg.content.data.canvasid);
                  this.canvas['jsterm-' + msg.content.data.canvasid].addEventListener('DOMNodeRemoved', function() {
                      canvas_removed(msg.content.data.canvasid);
                  });
                }
                if (typeof this.gr['jsterm-' + msg.content.data.canvasid] === 'undefined') {
                    this.gr['jsterm-' + msg.content.data.canvasid] = new GR('jsterm-' + msg.content.data.canvasid);
                }
                if (!this.args.hasOwnProperty('jsterm-' + msg.content.data.canvasid) || typeof this.args['jsterm-' + msg.content.data.canvasid] === 'undefined') {
                    this.args['jsterm-' + msg.content.data.canvasid] = this.gr['jsterm-' + msg.content.data.canvasid].newmeta();
                }
                if (document.getElementById('jsterm-' + msg.content.data.canvasid) == null) {
                    canvas_removed(msg.content.data.canvasid);
                    this.gr['jsterm-' + msg.content.data.canvasid] = undefined;
                    setTimeout(function(){refr_plot('jsterm-' + msg.content.data.canvasid, msg, 0);}, 5);
                } else {
                    this.gr['jsterm-' + msg.content.data.canvasid].readmeta(this.args['jsterm-' + msg.content.data.canvasid], msg.content.data.json);
                    this.gr['jsterm-' + msg.content.data.canvasid].select_canvas();
                    this.gr['jsterm-' + msg.content.data.canvasid].clearws();
                    this.gr['jsterm-' + msg.content.data.canvasid].plotmeta(this.args['jsterm-' + msg.content.data.canvasid]);
                }
            }
        }

        function refr_plot(id, msg, count) {
            if (count >= 500) {
              return;
            }
            if (document.getElementById(id) == null) {
                setTimeout(function(){refr_plot(id, msg, count + 1);}, 5);
            } else {
                draw(msg);
            }
        }

        function register_comm(kernel) {
            kernel.comm_manager.register_target('jsterm_comm', function(comm) {
                comm.on_msg(function(msg) {
                    draw(msg);
                });
                comm.on_close(function() {
                });
                window.addEventListener('beforeunload', function (e) {
                  comm.close();
                });
                this.comm = comm;
            });
        }

        function onLoad() {
            Jupyter.notebook.events.on('execution_request.Kernel', function() {
                for (var key in this.gr) {
                    if (this.args.hasOwnProperty(key)) {
                        this.gr[key].deletemeta(this.args[key]);
                    }
                }
                this.gr = [];
                this.args = [];
            });
            // TODO restart event
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
    JSTerm();
  }
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
    id_count += 1
    if !js_running
      inject_js()
      js_running = true
    end
    JSTermWidget(string(name, id), false)
  else
    error("JSTermWidget is only available in IJulia environments")
  end
end

function jsterm_display(widget::JSTermWidget)
  if GR.isijulia()
    display(HTML(string("<canvas id=\"jsterm-", widget.identifier, "\" width=\"500\" height=\"500\"></canvas>")))
    widget.visible = true
  else
    error("jsterm_display is only available in IJulia environments")
  end
end

function jsterm_send(widget::JSTermWidget, data::String)
  global js_running
  if GR.isijulia()
    comm = Main.IJulia.Comm("jsterm_comm")
    comm.on_close = function comm_close_callback(msg)
      global js_running
      js_running = false
    end
    comm.on_msg = function comm_msg_callback(msg)
      if haskey(msg.content["data"], "type")
        if msg.content["data"]["type"] == "removed"
          jswidgets[msg.content["data"]["content"]].visible = false
          jsterm_display(widget)
        end
      end
    end
    Main.IJulia.send_comm(comm, Dict("json" => data, "canvasid" => widget.identifier))
  else
    error("jsterm_send is only available in IJulia environments")
  end
end

function recv(name::Cstring, id::Int64, msg::Cstring)
    # receives string from C and sends it to JS via Comm
    global js_running
    if !js_running
      inject_js()
    end
    _name = unsafe_string(name)
    if haskey(jswidgets, string(_name, id))
        widget = jswidgets[string(_name, id)]
    else
        widget = JSTermWidget(_name, id)
        jswidgets[string(_name, id)] = widget
    end
    if !widget.visible
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
send_c = nothing
recv_c = nothing

function initjs()
    global jswidgets, send_c, recv_c

    jswidgets = Dict{String, JSTermWidget}()
    send_c = @cfunction(send, Cstring, (Cstring, Int64))
    recv_c = @cfunction(recv, Int32, (Cstring, Int64, Cstring))
    send_c, recv_c
end

end # module
