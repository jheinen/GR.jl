# This example requires CImGui#master
#
# import Pkg; Pkg.add(name="CImGui", rev="master")
#
using CImGui
using CImGui.ImGuiGLFWBackend
using CImGui.ImGuiGLFWBackend.LibCImGui
using CImGui.ImGuiGLFWBackend.LibGLFW
using CImGui.ImGuiOpenGLBackend
using CImGui.ImGuiOpenGLBackend.ModernGL
using CImGui.CSyntax
using CImGui.CSyntax.CStatic
using Printf

using GR
using LaTeXStrings

glfwDefaultWindowHints()
glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3)
glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 2)
if Sys.isapple()
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE) # 3.2+ only
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE) # required on Mac
end

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

# create window
window = glfwCreateWindow(960, 720, "Demo", C_NULL, C_NULL)
@assert window != C_NULL
glfwMakeContextCurrent(window)
glfwSwapInterval(1)  # enable vsync

# create OpenGL and GLFW context
window_ctx = ImGuiGLFWBackend.create_context(window)
gl_ctx = ImGuiOpenGLBackend.create_context()

# setup Dear ImGui context
ctx = CImGui.CreateContext()

# create texture for image drawing
img_width, img_height = 500, 500
image_id = ImGuiOpenGLBackend.ImGui_ImplOpenGL3_CreateImageTexture(img_width, img_height)

ENV["GKS_WSTYPE"] = "100"
image = rand(GLuint, img_width, img_height) # allocate the memory
mem = Printf.@sprintf("%p",pointer(image))
conid = Printf.@sprintf("!%dx%d@%s.mem",  img_width, img_height, mem[3:end])

# setup Platform/Renderer bindings
ImGuiGLFWBackend.init(window_ctx)
ImGuiOpenGLBackend.init(gl_ctx)

try
    clear_color = Cfloat[0.45, 0.55, 0.60, 1.00]
    while glfwWindowShouldClose(window) == 0
        glfwPollEvents()
        # start the Dear ImGui frame
        ImGuiOpenGLBackend.new_frame(gl_ctx)
        ImGuiGLFWBackend.new_frame(window_ctx)
        CImGui.NewFrame()

        # show image example
        CImGui.Begin("GR Demo")

        @cstatic phi = Cfloat(0.0) begin
            @c CImGui.SliderFloat("Angle", &phi, 0, 360, "%.4f")
            beginprint(conid)
            draw(phi * π/180)
            endprint()

            ImGuiOpenGLBackend.ImGui_ImplOpenGL3_UpdateImageTexture(image_id, image, img_width, img_height)
            CImGui.Image(Ptr{Cvoid}(image_id), CImGui.ImVec2(img_width, img_height))
            CImGui.End()
        end

        # rendering
        CImGui.Render()
        glfwMakeContextCurrent(window)

        width, height = Ref{Cint}(), Ref{Cint}() #! need helper fcn
        glfwGetFramebufferSize(window, width, height)
        display_w = width[]
        display_h = height[]

        glViewport(0, 0, display_w, display_h)
        glClearColor(clear_color...)
        glClear(GL_COLOR_BUFFER_BIT)
        ImGuiOpenGLBackend.render(gl_ctx)

        glfwMakeContextCurrent(window)
        glfwSwapBuffers(window)
    end
catch e
    @error "Error in renderloop!" exception=e
    Base.show_backtrace(stderr, catch_backtrace())
finally
    ImGuiOpenGLBackend.shutdown(gl_ctx)
    ImGuiGLFWBackend.shutdown(window_ctx)
    CImGui.DestroyContext(ctx)
    glfwDestroyWindow(window)
end
