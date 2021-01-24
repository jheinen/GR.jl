using CImGui
using CImGui.CSyntax
using CImGui.CSyntax.CStatic
using CImGui.GLFWBackend
using CImGui.OpenGLBackend
using CImGui.GLFWBackend.GLFW
using CImGui.OpenGLBackend.ModernGL
using Printf

using GR
using LaTeXStrings

const glsl_version = 150
GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 2)
GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE) # 3.2+ only
GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE) # required on Mac

function draw(phi)
    formulas = (
        L"- \frac{{\hbar ^2}}{{2m}}\frac{{\partial ^2 \psi (x,t)}}{{\partial x^2 }} + U(x)\psi (x,t) = i\hbar \frac{{\partial \psi (x,t)}}{{\partial t}}",
        L"\zeta \left({s}\right) := \sum_{n=1}^\infty \frac{1}{n^s} \quad \sigma = \Re(s) > 1",
        L"\zeta \left({s}\right) := \frac{1}{\Gamma(s)} \int_{0}^\infty \frac{x^{s-1}}{e^x-1} dx" )

    selntran(0)
    settextfontprec(232, 3)
    settextalign(2, 3)
    settextcolorind(0) # white
    chh = 0.036

    clearws()
    setcharheight(chh)
    setcharup(sin(phi), cos(phi))
    y = 0.6
    for s in formulas
        mathtex(0.5, y, s)
        tbx, tby = inqmathtex(0.5, y, s)
        fillarea(tbx, tby)
        y -= 0.2
    end
    updatews()
end

# setup GLFW error callback
error_callback(err::GLFW.GLFWError) = @error "GLFW ERROR: code $(err.code) msg: $(err.description)"
GLFW.SetErrorCallback(error_callback)

# create window
window = GLFW.CreateWindow(960, 720, "Demo")
@assert window != C_NULL
GLFW.MakeContextCurrent(window)
GLFW.SwapInterval(1)  # enable vsync

# setup Dear ImGui context
ctx = CImGui.CreateContext()

# create texture for image drawing
img_width, img_height = 500, 500
image_id = ImGui_ImplOpenGL3_CreateImageTexture(img_width, img_height)

ENV["GKS_WSTYPE"] = "100"
image = rand(GLuint, 4, img_width, img_height) # allocate the memory 
mem = Printf.@sprintf("%p",pointer(image))
conid = Printf.@sprintf("!%dx%d@%s.mem",  img_width, img_height, mem[3:end])

# setup Platform/Renderer bindings
ImGui_ImplGlfw_InitForOpenGL(window, true)
ImGui_ImplOpenGL3_Init(glsl_version)

try
    clear_color = Cfloat[0.45, 0.55, 0.60, 1.00]
    while !GLFW.WindowShouldClose(window)
        GLFW.PollEvents()
        # start the Dear ImGui frame
        ImGui_ImplOpenGL3_NewFrame()
        ImGui_ImplGlfw_NewFrame()
        CImGui.NewFrame()

        # show image example
        CImGui.Begin("GR Demo")

        @cstatic phi = Cfloat(0.0) begin
            @c CImGui.SliderFloat("Angle", &phi, 0, 360, "%.4f")
            beginprint(conid)
            draw(phi * π/180)
            endprint()
        end

        ImGui_ImplOpenGL3_UpdateImageTexture(image_id, image, img_width, img_height)
        CImGui.Image(Ptr{Cvoid}(image_id), (img_width, img_height))
        CImGui.End()

        # rendering
        CImGui.Render()
        GLFW.MakeContextCurrent(window)
        display_w, display_h = GLFW.GetFramebufferSize(window)
        glViewport(0, 0, display_w, display_h)
        glClearColor(clear_color...)
        glClear(GL_COLOR_BUFFER_BIT)
        ImGui_ImplOpenGL3_RenderDrawData(CImGui.GetDrawData())

        GLFW.MakeContextCurrent(window)
        GLFW.SwapBuffers(window)
    end
catch e
    @error "Error in renderloop!" exception=e
    Base.show_backtrace(stderr, catch_backtrace())
finally
    ImGui_ImplOpenGL3_Shutdown()
    ImGui_ImplGlfw_Shutdown()
    CImGui.DestroyContext(ctx)
    GLFW.HideWindow(window)
    GLFW.DestroyWindow(window)
end
