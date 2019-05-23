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
    if (typeof grJSTermRunning === 'undefined' || !grJstermReady) {
      BOXZOOM_THRESHOLD = 5;
      BOXZOOM_TRIGGER_THRESHHOLD = 1000;
      MAX_KERNEL_CONNECTION_ATTEMPTS = 25;
      KERNEL_CONNECT_WAIT_TIME = 100;
      REFRESH_PLOT_TIMEOUT = 100;
      BOXZOOM_FILL_STYLE = '#FFAAAA';
      BOXZOOM_STROKE_STYLE = '#FF0000';

      var comm = undefined;
      var idcount = 0;
      var widgets = [];
      var jupyterRunning = false;

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

      function sendEvt(data, id) {
        if (jupyterRunning) {
          comm.send({
            "type": "evt",
            "content": data,
            "id": id
          });
        }
      }

      function jsLoaded() {
        grJstermReady = true;
        for (let or in onready) {
          or();
          onready = [];
        }
      }

      function canvasRemoved(id) {
        if (jupyterRunning) {
          comm.send({
            "type": "removed",
            "content": id
          });
        }
      }

      function saveData(data, id) {
        if (jupyterRunning) {
          comm.send({
            "type": "save",
            "content": {
              "id": id,
              "data": JSON.stringify(data)
            }
          });
        }
      }

      function registerComm(kernel) {
        kernel.comm_manager.register_target('jsterm_comm', function(c) {
          c.on_msg(function(msg) {
            let data = msg.content.data;
            if (data.type == 'evt') {
              if (typeof widgets[data.id] !== 'undefined') {
                widgets[data.id].msgHandleEvent(data);
              }
            } else if (msg.content.data.type == 'cmd') {
              if (typeof data.id !== 'undefined') {
                if (typeof widgets[data.id] !== 'undefined') {
                  widgets[data.id].msgHandleCommand(data);
                }
              } else {
                for (let key in widgets) {
                  widgets[key].msgHandleCommand(data);
                }
              }
            } else if (data.type == 'draw') {
              draw(msg);
            }
          });
          c.on_close(function() {});
          window.addEventListener('beforeunload', function(e) {
            c.close();
          });
          comm = c;
        });
      }

      function onLoad() {
        if (typeof Jupyter !== 'undefined') {
          jupyterRunning = true;
          initKernel(1);
        } else {
          drawSavedData();
        }
      };

      function initKernel(attempt) {
        let kernel = Jupyter.notebook.kernel;
        if (typeof kernel === 'undefined' || kernel == null) {
          if (attempt < MAX_KERNEL_CONNECTION_ATTEMPTS) {
            setTimeout(function() {
              initKernel(attempt + 1);
            }, KERNEL_CONNECT_WAIT_TIME);
          }
        } else {
          registerComm(kernel);
          Jupyter.notebook.events.on('kernel_ready.Kernel', function() {
            registerComm(kernel);
            for (let key in widgets) {
              widgets[key].init();
            }
          });
          drawSavedData();
        }
      }

      function draw(msg) {
        if (!grJstermReady) {
          onready.push(function() {
            return draw(msg);
          });
        } else if (!GR.is_ready) {
          GR.ready(function() {
            return draw(msg);
          });
        } else {
          if (typeof widgets[msg.content.data.id] === 'undefined') {
            widgets[msg.content.data.id] = new JSTermWidget(idcount, msg.content.data.id);
            idcount += 1;
          }
          widgets[msg.content.data.id].draw(msg);
        }
      }

      function drawSavedData() {
        let data = document.getElementsByClassName("jsterm-data");
        for (let i = 0; i < data.length; i++) {
          let msg = data[i].innerText;
          draw(JSON.parse(msg));
        }
      }

      if (document.readyState!='loading') {
        onLoad();
      } else if (document.addEventListener) {
        document.addEventListener('DOMContentLoaded', onLoad);
      } else document.attachEvent('onreadystatechange', function() {
        if (document.readyState=='complete') {
          onLoad();
        }
      });


      function JSTermWidget(id, htmlId) {

        this.init = function() {
          this.canvas = undefined;
          this.overlayCanvas = undefined;
          this.args = undefined;
          this.id = id;  // context id for meta.c (switchmeta)
          this.gr = undefined;
          this.htmlId = htmlId;

          this.waiting = false;
          this.oncanvas = function() {};

          // event handling
          this.pinching = false;
          this.panning = false;
          this.prevMousePos = undefined;
          this.boxzoom = false;
          this.keepAspectRatio = true;
          this.boxzoomTriggerTimeout = undefined;
          this.boxzoomPoint = [0, 0];
          this.pinchDiff = 0;
          this.prevTouches = undefined;

          this.sendEvents = false;
          this.handleEvents = true;
        }

        this.init();

        this.sendEvt = function(data) {
          if (this.sendEvents) {
            sendEvt(data, this.htmlId);
          }
        }

        this.getCoords = function(event) {
          let rect = this.canvas.getBoundingClientRect();
          //TODO mind the canvas-padding if necessary!
          return [Math.floor(event.clientX - rect.left), Math.floor(event.clientY - rect.top)];
        };

        this.grEventinput = function(mouseargs) {
          this.gr.switchmeta(this.id);
          this.gr.inputmeta(mouseargs);
          this.gr.current_canvas = this.canvas;
          this.gr.current_context = this.gr.current_canvas.getContext('2d');
          this.gr.select_canvas();
          this.gr.plotmeta();
        };

        this.handleWheel = function(x, y, angle_delta) {
          if (typeof this.boxzoomTriggerTimeout !== 'undefined') {
            clearTimeout(this.boxzoomTriggerTimeout);
          }
          let mouseargs = this.gr.newmeta();
          this.gr.meta_args_push(mouseargs, "x", "i", [x]);
          this.gr.meta_args_push(mouseargs, "y", "i", [y]);
          this.gr.meta_args_push(mouseargs, "angle_delta", "d", [angle_delta]);
          this.grEventinput(mouseargs);
        };

        this.mouseHandleWheel = function (event) {
          let coords = this.getCoords(event);
          this.sendEvt({
            "x": coords[0],
            "y": coords[1],
            "angle_delta": event.deltaY,
            "event": "mousewheel",
          });
          if (this.handleEvents) {
            this.handleWheel(coords[0], coords[1], event.deltaY);
          }
          event.preventDefault();
        };

        this.handleMousedown = function(x, y, button, ctrlKey) {
          if (typeof this.boxzoomTriggerTimeout !== 'undefined') {
            clearTimeout(this.boxzoomTriggerTimeout);
          }
          if (button == 0) {
            this.overlayCanvas.style.cursor = 'move';
            this.panning = true;
            this.boxzoom = false;
            this.prevMousePos = [x, y];
            this.boxzoomTriggerTimeout = setTimeout(function() {this.startBoxzoom(x, y, ctrlKey);}.bind(this), BOXZOOM_TRIGGER_THRESHHOLD);
          } else if (button == 2) {
            this.startBoxzoom(x, y, ctrlKey);
          }
        };

        this.mouseHandleMousedown = function (event) {
          let coords = this.getCoords(event);
          this.sendEvt({
            "x": coords[0],
            "y": coords[1],
            "button": event.button,
            "ctrlKey": event.ctrlKey,
            "event": "mousedown",
          });
          if (this.handleEvents) {
            this.handleMousedown(coords[0], coords[1], event.button, event.ctrlKey);
          }
          event.preventDefault();
        };

        this.startBoxzoom = function(x, y, ctrlKey) {
          this.panning = false;
          this.boxzoom = true;
          if (ctrlKey) {
            this.keepAspectRatio = false;
          }
          this.boxzoomPoint = [x, y];
          this.overlayCanvas.style.cursor = 'nwse-resize';
        };

        this.handleMouseup = function(x, y, button) {
          if (typeof this.boxzoomTriggerTimeout !== 'undefined') {
            clearTimeout(this.boxzoomTriggerTimeout);
          }
          if (this.boxzoom) {
            if ((Math.abs(this.boxzoomPoint[0] - x) >= BOXZOOM_THRESHOLD) && (Math.abs(this.boxzoomPoint[1] - y) >= BOXZOOM_THRESHOLD)) {
              let mouseargs = this.gr.newmeta();
              if (this.boxzoomPoint[0] < x) {
                this.gr.meta_args_push(mouseargs, "left", "i", [this.boxzoomPoint[0]]);
                this.gr.meta_args_push(mouseargs, "right", "i", [x]);
              } else {
                this.gr.meta_args_push(mouseargs, "right", "i", [this.boxzoomPoint[0]]);
                this.gr.meta_args_push(mouseargs, "left", "i", [x]);
              }
              if (this.boxzoomPoint[1] < y) {
                this.gr.meta_args_push(mouseargs, "top", "i", [this.boxzoomPoint[1]]);
                this.gr.meta_args_push(mouseargs, "bottom", "i", [y]);
              } else {
                this.gr.meta_args_push(mouseargs, "bottom", "i", [this.boxzoomPoint[1]]);
                this.gr.meta_args_push(mouseargs, "top", "i", [y]);
              }
              if (this.keepAspectRatio) {
                this.gr.meta_args_push(mouseargs, "keepAspectRatio", "i", [1]);
              } else {
                this.gr.meta_args_push(mouseargs, "keepAspectRatio", "i", [0]);
              }
              this.grEventinput(mouseargs);
            }
          }
          this.prevMousePos = undefined;
          this.overlayCanvas.style.cursor = 'auto';
          this.panning = false;
          this.boxzoom = false;
          this.keepAspectRatio = true;
          let context = this.overlayCanvas.getContext('2d');
          context.clearRect(0, 0, this.overlayCanvas.width, this.overlayCanvas.height);
        };

        this.mouseHandleMouseup = function(event) {
          let coords = this.getCoords(event);
          this.sendEvt({
            "x": coords[0],
            "y": coords[1],
            "button": event.button,
            "event": "mouseup",
          });
          if (this.handleEvents) {
            this.handleMouseup(coords[0], coords[1], event.button);
          }
          event.preventDefault();
        };

        this.touchHandleTouchstart = function(event) {
          if (event.touches.length == 1) {
            let coords = this.getCoords(event.touches[0])
            this.handleMousedown(coords[0], coords[1], 0, false);
          } else if (event.touches.length == 2) {
            this.pinching = true;
            this.pinchDiff = Math.abs(event.touches[0].clientX - event.touches[1].clientX) + Math.abs(event.touches[0].clientY - event.touches[1].clientY);
            let c1 = this.getCoords(event.touches[0]);
            let c2 = this.getCoords(event.touches[1]);
            this.prevTouches = [c1, c2];
          } else if (event.touches.length == 3) {
            let coords1 = this.getCoords(event.touches[0])
            let coords2 = this.getCoords(event.touches[1])
            let coords3 = this.getCoords(event.touches[2])
            let x = 1. / 3. * coords1[0] + coords2[0] + coords3[0];
            let y = 1. / 3. * coords1[1] + coords2[1] + coords3[1];
            this.handleDoubleclick(x, y);
          }
          event.preventDefault();
        };

        this.touchHandleTouchend = function(event) {
          this.handleMouseleave();
        };

        this.touchHandleTouchmove = function(event) {
          if (event.touches.length == 1) {
            let coords = this.getCoords(event.touches[0]);
            this.handleMousemove(coords[0], coords[1]);
          } else if (this.pinching && event.touches.length == 2) {
            let c1 = this.getCoords(event.touches[0]);
            let c2 = this.getCoords(event.touches[1]);
            let diff = Math.sqrt(Math.pow(Math.abs(c1[0] - c2[0]), 2) + Math.pow(Math.abs(c1[1] - c2[1]), 2));
            let factor = this.pinchDiff / diff;

            let mouseargs = this.gr.newmeta();
            this.gr.meta_args_push(mouseargs, "x", "i", [(c1[0] + c2[0]) / 2]);
            this.gr.meta_args_push(mouseargs, "y", "i", [(c1[1] + c2[1]) / 2]);
            this.gr.meta_args_push(mouseargs, "factor", "d", [factor]);
            this.grEventinput(mouseargs);

            let panmouseargs = this.gr.newmeta();
            this.gr.meta_args_push(panmouseargs, "x", "i", [(c1[0] + c2[0]) / 2]);
            this.gr.meta_args_push(panmouseargs, "y", "i", [(c1[1] + c2[1]) / 2]);
            this.gr.meta_args_push(panmouseargs, "xshift", "i", [(c1[0] - this.prevTouches[0][0] + c2[0] - this.prevTouches[1][0]) / 2.0]);
            this.gr.meta_args_push(panmouseargs, "yshift", "i", [(c1[1] - this.prevTouches[0][1] + c2[1] - this.prevTouches[1][1]) / 2.0]);
            this.grEventinput(panmouseargs);

            this.pinchDiff = diff;
            this.prevTouches = [c1, c2];
          }
          event.preventDefault();
        };

        this.handleMouseleave = function() {
          if (typeof this.boxzoomTriggerTimeout !== 'undefined') {
            clearTimeout(this.boxzoomTriggerTimeout);
          }
          this.overlayCanvas.style.cursor = 'auto';
          this.panning = false;
          this.prevMousePos = undefined;
          if (this.boxzoom) {
            let context = this.overlayCanvas.getContext('2d');
            context.clearRect(0, 0, this.overlayCanvas.width, this.overlayCanvas.height);
          }
          this.boxzoom = false;
          this.keepAspectRatio = true;
        };

        this.mouseHandleMouseleave = function(event) {
          this.sendEvt({
            "event": "mouseleave",
          });
          if (this.handleEvents) {
            this.handleMouseleave();
          }
        };

        this.handleMousemove = function(x, y) {
          if (this.panning) {
            if (typeof this.boxzoomTriggerTimeout !== 'undefined') {
              clearTimeout(this.boxzoomTriggerTimeout);
            }
            let mouseargs = this.gr.newmeta();
            this.gr.meta_args_push(mouseargs, "x", "i", [this.prevMousePos[0]]);
            this.gr.meta_args_push(mouseargs, "y", "i", [this.prevMousePos[1]]);
            this.gr.meta_args_push(mouseargs, "xshift", "i", [x - this.prevMousePos[0]]);
            this.gr.meta_args_push(mouseargs, "yshift", "i", [y - this.prevMousePos[1]]);
            this.grEventinput(mouseargs);
            this.prevMousePos = [x, y];
          } else if (this.boxzoom) {
            let context = this.overlayCanvas.getContext('2d');
            let diff = [x - this.boxzoomPoint[0], y - this.boxzoomPoint[1]];
            if (this.keepAspectRatio) {
              if (Math.abs(diff[0]) / this.overlayCanvas.width > Math.abs(diff[1]) / this.overlayCanvas.height) {
                let factor = Math.abs(x - this.boxzoomPoint[0]) / this.overlayCanvas.width;
                diff[1] = Math.sign(diff[1]) * factor * this.overlayCanvas.height;
              } else {
                let factor = Math.abs(y - this.boxzoomPoint[1]) / this.overlayCanvas.height;
                diff[0] = Math.sign(diff[0]) * factor * this.overlayCanvas.width;
              }
            }
            context.clearRect(0, 0, this.overlayCanvas.width, this.overlayCanvas.height);
            if (diff[0] * diff[1] >= 0) {
              this.overlayCanvas.style.cursor = 'nwse-resize';
            } else {
              this.overlayCanvas.style.cursor = 'nesw-resize';
            }
            context.fillStyle = BOXZOOM_FILL_STYLE;
            context.strokeStyle = BOXZOOM_STROKE_STYLE;
            context.beginPath();
            context.rect(this.boxzoomPoint[0], this.boxzoomPoint[1], diff[0], diff[1]);
            context.globalAlpha = 0.2;
            context.fill();
            context.globalAlpha = 1.0;
            context.stroke();
            context.closePath();
          }
        };

        this.mouseHandleMousemove = function (event) {
          let coords = this.getCoords(event);
          this.sendEvt({
            "x": coords[0],
            "y": coords[1],
            "event": "mousemove",
          });
          if (this.handleEvents) {
            this.handleMousemove(coords[0], coords[1]);
          }
          event.preventDefault();
        };

        this.handleDoubleclick = function(x, y) {
          let mouseargs = this.gr.newmeta();
          this.gr.meta_args_push(mouseargs, "x", "i", [x]);
          this.gr.meta_args_push(mouseargs, "y", "i", [y]);
          this.gr.meta_args_push(mouseargs, "key", "s", "r");
          this.grEventinput(mouseargs);
        };

        this.mouseHandleDoubleclick = function(event) {
          let coords = this.getCoords(event);
          this.sendEvt({
            "x": coords[0],
            "y": coords[1],
            "event": "doubleclick",
          });
          if (this.handleEvents) {
            this.handleDoubleclick(coords[0], coords[1]);
          }
          event.preventDefault();
        };

        this.msgHandleEvent = function(msg) {
          switch(msg.event) {
            case "mousewheel":
              this.handleWheel(msg.x, msg.y, msg.angle_delta);
              break;
            case "mousedown":
              this.handleMousedown(msg.x, msg.y, msg.button, msg.ctrlKey);
              break;
            case "mouseup":
              this.handleMouseup(msg.x, msg.y, msg.button);
              break;
            case "mousemove":
              this.handleMousemove(msg.x, msg.y);
              break;
            case "doubleclick":
              this.handleDoubleclick(msg.x, msg.y);
              break;
            case "mouseleave":
              this.handleMouseleave();
              break;
            default:
              break;
          }
        };

        this.msgHandleCommand = function(msg) {
          switch(msg.command) {
            case 'enable_events':
              this.sendEvents = true;
              break;
            case 'disable_events':
              this.sendEvents = false;
              break;
            case 'enable_jseventhandling':
              this.handleEvents = true;
              break;
            case 'disable_jseventhandling':
              this.handleEvents = false;
              break;
            default:
              break;
          }
        };

        this.draw = function(msg) {
          if (this.waiting) {
            this.oncanvas = function() {
              return this.draw(msg);
            };
          } else {
            if (document.getElementById('jsterm-' + msg.content.data.id) == null) {
              canvasRemoved(msg.content.data.id);
              this.canvas = undefined;
              this.waiting = true;
              this.oncanvas = function() {
                return draw(msg);
              };
              setTimeout(function() {
                this.refreshPlot(msg, 0);
              }.bind(this), REFRESH_PLOT_TIMEOUT);
            } else {
              if (document.getElementById('jsterm-data-' + this.htmlId) == null) {
                saveData(msg, msg.content.data.id);
              }
              if (typeof this.canvas === 'undefined' || typeof this.overlayCanvas === 'undefined') {
                this.canvas = document.getElementById('jsterm-' + this.htmlId);
                this.overlayCanvas = document.getElementById('jsterm-overlay-' + this.htmlId);
                this.overlayCanvas.addEventListener('DOMNodeRemoved', function() {
                  canvasRemoved(msg.content.data.id);
                  this.canvas = undefined;
                  this.waiting = true;
                  this.oncanvas = function() {};
                });
                this.overlayCanvas.style.cursor = 'auto';

                //registering event handler
                this.overlayCanvas.addEventListener('wheel', function(evt) { this.mouseHandleWheel(evt); }.bind(this));
                this.overlayCanvas.addEventListener('mousedown', function(evt) { this.mouseHandleMousedown(evt); }.bind(this));
                this.overlayCanvas.addEventListener('touchstart', function(evt) { this.touchHandleTouchstart(evt); }.bind(this));
                this.overlayCanvas.addEventListener('touchmove', function(evt) { this.touchHandleTouchmove(evt); }.bind(this));
                this.overlayCanvas.addEventListener('touchend', function(evt) { this.touchHandleTouchend(evt); }.bind(this));
                this.overlayCanvas.addEventListener('mousemove', function(evt) { this.mouseHandleMousemove(evt); }.bind(this));
                this.overlayCanvas.addEventListener('mouseup', function(evt) { this.mouseHandleMouseup(evt); }.bind(this));
                this.overlayCanvas.addEventListener('mouseleave', function(evt) { this.mouseHandleMouseleave(evt); }.bind(this));
                this.overlayCanvas.addEventListener('dblclick', function(evt) { this.mouseHandleDoubleclick(evt); }.bind(this));
                this.overlayCanvas.addEventListener('contextmenu', function(event) {
                  event.preventDefault();
                  return false;
                });
              }
              if (typeof this.gr === 'undefined') {
                this.gr = new GR('jsterm-' + this.htmlId);
              }
              if (typeof this.args === 'undefined') {
                this.args = this.gr.newmeta();
              }
              this.waiting = false;
              this.gr.switchmeta(this.id);
              this.gr.current_canvas = this.canvas; //TODO is this always set? (check)
              this.gr.current_context = this.gr.current_canvas.getContext('2d');
              this.gr.select_canvas();
              this.gr.meta_args_push(this.args, "size", "dd", [this.canvas.width, this.canvas.height]);
              this.gr.readmeta(this.args, msg.content.data.json);
              this.gr.plotmeta(this.args);
            }
          }
        };

        this.refreshPlot = function(msg, count) {
          if (document.getElementById('jsterm-' + this.htmlId) == null) {
            setTimeout(function() {
              this.refreshPlot(msg, count + 1);
            }.bind(this), REFRESH_PLOT_TIMEOUT);
          } else {
            this.waiting = false;
            if (typeof this.oncanvas !== 'undefined') {
              this.oncanvas();
            }
          }
        };
      }
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
    display(HTML(string("<div style=\"position: relative; width: ", widget.width, "px; height: ", widget.height, "px;\"><canvas id=\"jsterm-overlay-", widget.identifier, "\" style=\"position:absolute; top: 0; right: 0; z-index: 1;\" width=\"", widget.width, "\" height=\"", widget.height, "\"></canvas>
        <canvas id=\"jsterm-", widget.identifier, "\" style=\"position: absolute; top: 0; right: 0; z-index: 0;\"width=\"", widget.width, "\" height=\"", widget.height, "\"></canvas>")))
    widget.visible = true
  else
    error("jsterm_display is only available in IJulia environments")
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

function jsterm_send(widget::JSTermWidget, data::String)
  global js_running, draw_condition, comm, PXWIDTH, PXHEIGHT, counter
  if GR.isijulia()
    if comm === nothing
      comm = Main.IJulia.Comm("jsterm_comm")
      comm.on_close = function comm_close_callback(msg)
        global js_running
        js_running = false
      end
      comm.on_msg = function comm_msg_callback(msg)
        data = msg.content["data"]
        if haskey(data, "type")
          if data["type"] == "removed"
            jswidgets[data["content"]].visible = false
            jsterm_display(jswidgets[data["content"]])
          elseif data["type"] == "save"
            display(HTML(string("<div style=\"display:none;\" id=\"jsterm-data-", data["content"]["id"], "\" class=\"jsterm-data\">", data["content"]["data"], "</div>")))
          elseif data["type"] == "evt"
            global_evthandler(data["content"])
            if haskey(evthandler, data["id"]) && evthandler[data["id"]] !== nothing
              evthandler[data["id"]](data["content"])
            end
          end
        end
      end
    end
    Main.IJulia.send_comm(comm, Dict("json" => data, "type"=>"draw", "id" => widget.identifier))
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
