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


mutable struct JSTermWidget
    identifier::String
    width::Int
    height::Int
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
  _jsterm = """
    if (typeof grJSTermRunning === 'undefined') {
      function JSTerm() {
        this.BOXZOOM_THRESHOLD = 5;
        this.BOXZOOM_TRIGGER_THRESHHOLD = 1000;

        function init() {
          this.onready = [];
          this.gr = [];
          this.args = [];
          this.canvas = [];
          this.overlay_canvas = [];
          this.comm = undefined;
          this.waiting = [];
          this.oncanv = [];
          this.panning = false;
          this.prev_mouse_pos = undefined;
          this.boxzoom = false;
          this.keep_aspect_ratio = true;
          this.boxzoom_point = [0, 0];
          this.boxzoomTriggerTimeout = undefined;
        }

        init();

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

        function getCoords(canv, event) {
          let rect = canv.getBoundingClientRect();
          //TODO mind the canvas-padding if necessary!
          return [event.clientX - rect.left, event.clientY - rect.top];
        }

        function jsLoaded() {
          grJstermReady = true;
          for (let i = 0; i < this.onready.length; i++) {
            this.onready[i]();
          }
          this.onready = [];
        }

        function canvas_removed(id) {
          this.comm.send({
            "type": "removed",
            "content": id
          })
        }

        function handlewheel(event, canv, comm, gr, args) {
          if (typeof this.boxzoomTriggerTimeout !== 'undefined') {
            clearTimeout(this.boxzoomTriggerTimeout);
          }
          let mouseargs = gr.newmeta();
          let coords = getCoords(canv, event);
          gr.meta_args_push(mouseargs, "x", "i", [coords[0]]);
          gr.meta_args_push(mouseargs, "y", "i", [coords[1]]);
          gr.meta_args_push(mouseargs, "angle_delta", "d", [event.deltaY]);
          gr.dumpmeta_json(mouseargs, gr.get_stdout());
          gr.inputmeta(mouseargs);
          gr.plotmeta();
          event.preventDefault();
        }

        function handleMousedown(event, canv, comm, gr, args) {
          if (typeof this.boxzoomTriggerTimeout !== 'undefined') {
            clearTimeout(this.boxzoomTriggerTimeout);
          }
          if (event.button == 0) {
            canv.style.cursor = 'move';
            this.panning = true;
            this.boxzoom = false;
            this.prev_mouse_pos = getCoords(canv, event);
            this.boxzoomTriggerTimeout = setTimeout(function() {startBoxzoom(event, canv)}, this.BOXZOOM_TRIGGER_THRESHHOLD);
          } else if (event.button == 2) {
            startBoxzoom(event, canv);
          }
        }

        function startBoxzoom(event, canv) {
          this.panning = false;
          this.boxzoom = true;
          if (event.ctrlKey) {
            this.keep_aspect_ratio = false;
          }
          this.boxzoom_point = getCoords(canv, event);
          canv.style.cursor = 'nwse-resize';
        }

        function handleMouseup(event, canv, comm, gr, args) {
          if (typeof this.boxzoomTriggerTimeout !== 'undefined') {
            clearTimeout(this.boxzoomTriggerTimeout);
          }
          if (this.boxzoom) {
            let coords = getCoords(canv, event);
            if ((Math.abs(this.boxzoom_point[0] - coords[0]) >= this.BOXZOOM_THRESHOLD) && (Math.abs(this.boxzoom_point[1] - coords[1]) >= this.BOXZOOM_THRESHOLD)) {
              let mouseargs = gr.newmeta();
              if (this.boxzoom_point[0] < coords[0]) {
                gr.meta_args_push(mouseargs, "left", "i", [this.boxzoom_point[0]]);
                gr.meta_args_push(mouseargs, "right", "i", [coords[0]]);
              } else {
                gr.meta_args_push(mouseargs, "right", "i", [this.boxzoom_point[0]]);
                gr.meta_args_push(mouseargs, "left", "i", [coords[0]]);
              }
              if (this.boxzoom_point[1] < coords[1]) {
                gr.meta_args_push(mouseargs, "top", "i", [this.boxzoom_point[1]]);
                gr.meta_args_push(mouseargs, "bottom", "i", [coords[1]]);
              } else {
                gr.meta_args_push(mouseargs, "bottom", "i", [this.boxzoom_point[1]]);
                gr.meta_args_push(mouseargs, "top", "i", [coords[1]]);
              }
              if (this.keep_aspect_ratio) {
                gr.meta_args_push(mouseargs, "keep_aspect_ratio", "i", [1]);
              } else {
                gr.meta_args_push(mouseargs, "keep_aspect_ratio", "i", [0]);
              }
              gr.inputmeta(mouseargs);
              gr.plotmeta();
            }
          } else if (this.panning) {
            this.prev_mouse_pos = undefined;
          }
          canv.style.cursor = 'auto';
          this.panning = false;
          this.boxzoom = false;
          this.keep_aspect_ratio = true;
          let context = canv.getContext('2d');
          context.clearRect(0, 0, canv.width, canv.height);
        }

        function handleMouseleave(event, canv, comm, gr, args) {
          if (typeof this.boxzoomTriggerTimeout !== 'undefined') {
            clearTimeout(this.boxzoomTriggerTimeout);
          }
          canv.style.cursor = 'auto';
          this.panning = false;
          this.prev_mouse_pos = undefined;
          if (this.boxzoom) {
            let context = canv.getContext('2d');
            context.clearRect(0, 0, canv.width, canv.height);
          }
          this.boxzoom = false;
          this.keep_aspect_ratio = true;
        }

        function handleMousemove(event, canv, comm, gr, args) {
          let coords = getCoords(canv, event);
          if (this.panning) {
            if (typeof this.boxzoomTriggerTimeout !== 'undefined') {
              clearTimeout(this.boxzoomTriggerTimeout);
            }
            let mouseargs = gr.newmeta();
            gr.meta_args_push(mouseargs, "x", "i", [this.prev_mouse_pos[0]]);
            gr.meta_args_push(mouseargs, "y", "i", [this.prev_mouse_pos[1]]);
            gr.meta_args_push(mouseargs, "xshift", "i", [coords[0] - this.prev_mouse_pos[0]]);
            gr.meta_args_push(mouseargs, "yshift", "i", [coords[1] - this.prev_mouse_pos[1]]);
            gr.inputmeta(mouseargs);
            gr.plotmeta();
            this.prev_mouse_pos = [coords[0], coords[1]];
            event.preventDefault();
          } else if (this.boxzoom) {
            let context = canv.getContext('2d');
            let mousex = coords[0];
            let mousey = coords[1];
            let diff = [mousex - this.boxzoom_point[0], mousey - this.boxzoom_point[1]];
            if (this.keep_aspect_ratio) {
              if (Math.abs(diff[0]) / canv.width > Math.abs(diff[1]) / canv.height) {
                let factor = Math.abs(coords[0] - this.boxzoom_point[0]) / canv.width
                diff[1] = Math.sign(diff[1]) * factor * canv.height;
              } else {
                let factor = Math.abs(coords[1] - this.boxzoom_point[1]) / canv.height;
                diff[0] = Math.sign(diff[0]) * factor * canv.width;
              }
            }
            context.clearRect(0, 0, canv.width, canv.height);
            if (diff[0] * diff[1] >= 0) {
              canv.style.cursor = 'nwse-resize';
            } else {
              canv.style.cursor = 'nesw-resize';
            }
            context.fillStyle = '#FFAAAA';
            context.strokeStyle = '#FF0000';
            context.beginPath();
            context.rect(this.boxzoom_point[0], this.boxzoom_point[1], diff[0], diff[1]);
            context.globalAlpha = 0.2;
            context.fill();
            context.globalAlpha = 1.0;
            context.stroke();
            context.closePath();
            event.preventDefault();
          }
        }

        function handleDoubleclick(event, canv, comm, gr, args) {
          let mouseargs = gr.newmeta();
          let coords = getCoords(canv, event);
          gr.meta_args_push(mouseargs, "x", "i", [coords[0]]);
          gr.meta_args_push(mouseargs, "y", "i", [coords[1]]);
          gr.meta_args_push(mouseargs, "key", "s", "r");
          gr.inputmeta(mouseargs);
          gr.plotmeta();
          event.preventDefault();
        }

        function draw(msg) {
          if (typeof this.waiting['jsterm-' + msg.content.data.canvasid] === 'undefined') {
            this.waiting['jsterm-' + msg.content.data.canvasid] = false;
          }
          if (!grJstermReady) {
            this.onready.push(function() {
              return draw(msg);
            });
          } else if (!GR.is_ready) {
            GR.ready(function() {
              return draw(msg);
            });
          } else if (this.waiting['jsterm-' + msg.content.data.canvasid]) {
            this.oncanv['jsterm-' + msg.content.data.canvasid] = function() {
              return draw(msg);
            };
          } else {
            if (document.getElementById('jsterm-' + msg.content.data.canvasid) == null) {
              canvas_removed(msg.content.data.canvasid);
              this.canvas['jsterm-' + msg.content.data.canvasid] = undefined;
              this.waiting['jsterm-' + msg.content.data.canvasid] = true;
              this.oncanv['jsterm-' + msg.content.data.canvasid] = undefined;
              this.oncanv['jsterm-' + msg.content.data.canvasid] = function() {
                return draw(msg);
              };
              setTimeout(function() {
                refr_plot('jsterm-' + msg.content.data.canvasid, msg, 0);
              }, 100);
            } else {
              if (typeof this.canvas['jsterm-' + msg.content.data.canvasid] === 'undefined') {
                this.canvas['jsterm-' + msg.content.data.canvasid] = document.getElementById('jsterm-' + msg.content.data.canvasid);
                this.overlay_canvas['jsterm-' + msg.content.data.canvasid] = document.getElementById('jsterm-overlay-' + msg.content.data.canvasid);
                this.overlay_canvas['jsterm-' + msg.content.data.canvasid].addEventListener('DOMNodeRemoved', function() {
                  canvas_removed(msg.content.data.canvasid);
                  this.waiting['jsterm-' + msg.content.data.canvasid] = true;
                  this.oncanv['jsterm-' + msg.content.data.canvasid] = undefined;
                });
                this.overlay_canvas['jsterm-' + msg.content.data.canvasid].addEventListener('wheel', function(evt) {
                  handlewheel(evt, this.overlay_canvas['jsterm-' + msg.content.data.canvasid], this.comm, this.gr['jsterm-' + msg.content.data.canvasid], this.args['jsterm-' + msg.content.data.canvasid]);
                }.bind(this));
                this.overlay_canvas['jsterm-' + msg.content.data.canvasid].addEventListener('mousedown', function(evt) {
                  handleMousedown(evt, this.overlay_canvas['jsterm-' + msg.content.data.canvasid], this.comm, this.gr['jsterm-' + msg.content.data.canvasid], this.args['jsterm-' + msg.content.data.canvasid]);
                }.bind(this));
                this.overlay_canvas['jsterm-' + msg.content.data.canvasid].addEventListener('mousemove', function(evt) {
                  handleMousemove(evt, this.overlay_canvas['jsterm-' + msg.content.data.canvasid], this.comm, this.gr['jsterm-' + msg.content.data.canvasid], this.args['jsterm-' + msg.content.data.canvasid]);
                }.bind(this));
                this.overlay_canvas['jsterm-' + msg.content.data.canvasid].addEventListener('mouseup', function(evt) {
                  handleMouseup(evt, this.overlay_canvas['jsterm-' + msg.content.data.canvasid], this.comm, this.gr['jsterm-' + msg.content.data.canvasid], this.args['jsterm-' + msg.content.data.canvasid]);
                }.bind(this));
                this.overlay_canvas['jsterm-' + msg.content.data.canvasid].addEventListener('mouseleave', function(evt) {
                  handleMouseleave(evt, this.overlay_canvas['jsterm-' + msg.content.data.canvasid], this.comm, this.gr['jsterm-' + msg.content.data.canvasid], this.args['jsterm-' + msg.content.data.canvasid]);
                }.bind(this));
                this.overlay_canvas['jsterm-' + msg.content.data.canvasid].addEventListener('dblclick', function(evt) {
                  handleDoubleclick(evt, this.overlay_canvas['jsterm-' + msg.content.data.canvasid], this.comm, this.gr['jsterm-' + msg.content.data.canvasid], this.args['jsterm-' + msg.content.data.canvasid]);
                }.bind(this));
                this.overlay_canvas['jsterm-' + msg.content.data.canvasid].addEventListener('contextmenu', function(event) {
                  event.preventDefault();
                  return false;
                });
                this.overlay_canvas['jsterm-' + msg.content.data.canvasid].style.cursor = 'auto';
              }
              if (typeof this.gr['jsterm-' + msg.content.data.canvasid] === 'undefined') {
                this.gr['jsterm-' + msg.content.data.canvasid] = new GR('jsterm-' + msg.content.data.canvasid);
              }
              if (!this.args.hasOwnProperty('jsterm-' + msg.content.data.canvasid) || typeof this.args['jsterm-' + msg.content.data.canvasid] === 'undefined') {
                this.args['jsterm-' + msg.content.data.canvasid] = this.gr['jsterm-' + msg.content.data.canvasid].newmeta();
              }
              this.waiting['jsterm-' + msg.content.data.canvasid] = false;
              this.gr['jsterm-' + msg.content.data.canvasid].current_canvas = document.getElementById('jsterm-' + msg.content.data.canvasid);
              this.gr['jsterm-' + msg.content.data.canvasid].current_context = this.gr['jsterm-' + msg.content.data.canvasid].current_canvas.getContext('2d');
              this.gr['jsterm-' + msg.content.data.canvasid].select_canvas();
              this.gr['jsterm-' + msg.content.data.canvasid].meta_args_push(this.args['jsterm-' + msg.content.data.canvasid], "size", "dd", [this.canvas['jsterm-' + msg.content.data.canvasid].width, this.canvas['jsterm-' + msg.content.data.canvasid].height]);
              this.gr['jsterm-' + msg.content.data.canvasid].readmeta(this.args['jsterm-' + msg.content.data.canvasid], msg.content.data.json);
              this.gr['jsterm-' + msg.content.data.canvasid].plotmeta(this.args['jsterm-' + msg.content.data.canvasid]);
            }
          }
        }

        function refr_plot(id, msg, count) {
          /*if (count >= 100) {
            return;
          }*/
          // TODO: global count, that resets on new message / activity
          if (document.getElementById(id) == null) {
            setTimeout(function() {
              refr_plot(id, msg, count + 1);
            }, 100);
          } else {
            this.waiting['jsterm-' + msg.content.data.canvasid] = false;
            if (typeof this.oncanv['jsterm-' + msg.content.data.canvasid] !== 'undefined') {
              this.oncanv['jsterm-' + msg.content.data.canvasid]();
            }
          }
        }

        function register_comm(kernel) {
          kernel.comm_manager.register_target('jsterm_comm', function(comm) {
            comm.on_msg(function(msg) {
              draw(msg);
            });
            comm.on_close(function() {});
            window.addEventListener('beforeunload', function(e) {
              comm.close();
            });
            this.comm = comm;
          });
        }

        function onLoad() {
          let kernel = Jupyter.notebook.kernel;
          if (typeof kernel === 'undefined' || kernel == null) {
            console.error('JSTerm: No kernel detected');
            return;
          }
          register_comm(kernel);
          Jupyter.notebook.events.on('kernel_ready.Kernel', function() {
            kernel = IPython.notebook.kernel;
            init();
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
        JSTerm.saveLoad('""", _js_fallback, """', jsLoaded, 10000);
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
    JSTermWidget(string(name, id), pxwidth, pxheight, false)
  else
    error("JSTermWidget is only available in IJulia environments")
  end
end

function jsterm_display(widget::JSTermWidget)
  global pxwidth, pxheight
  if GR.isijulia()
    display(HTML(string("<div style=\"position: relative; width: ", widget.width, "px; height: ", widget.height, "px;\"><canvas id=\"jsterm-overlay-", widget.identifier, "\" style=\"position:absolute; top: 0; right: 0; z-index: 1;\" width=\"", widget.width, "\" height=\"", widget.height, "\"></canvas><canvas id=\"jsterm-", widget.identifier, "\" style=\"position: absolute; top: 0; right: 0; z-index: 0;\"width=\"", widget.width, "\" height=\"", widget.height, "\"></canvas>")))
    widget.visible = true
  else
    error("jsterm_display is only available in IJulia environments")
  end
end

comm = nothing

function jsterm_send(widget::JSTermWidget, data::String)
  global js_running, draw_condition, comm, PXWIDTH, PXHEIGHT
  if GR.isijulia()
    if comm === nothing
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
      js_running = true
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
