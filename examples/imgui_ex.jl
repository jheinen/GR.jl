using CImGui
using CImGui.lib
using CImGui.CSyntax
using CImGui.CSyntax.CStatic

import GLFW
import ModernGL as GL

using GR
using LaTeXStrings
using Printf

CImGui.set_backend(:GlfwOpenGL3)

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

function gr_demo(; engine=nothing)
    # setup Dear ImGui context
    ctx = CImGui.CreateContext()

    # enable docking and multi-viewport
    io = CImGui.GetIO()
    io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_DockingEnable
    io.ConfigFlags = unsafe_load(io.ConfigFlags) | CImGui.ImGuiConfigFlags_ViewportsEnable

    # setup Dear ImGui style
    CImGui.StyleColorsDark()

    # When viewports are enabled we tweak WindowRounding/WindowBg so platform windows can look identical to regular ones.
    style = Ptr{ImGuiStyle}(CImGui.GetStyle())
    if unsafe_load(io.ConfigFlags) & ImGuiConfigFlags_ViewportsEnable == ImGuiConfigFlags_ViewportsEnable
        style.WindowRounding = 5.0f0
        col = CImGui.c_get(style.Colors, CImGui.ImGuiCol_WindowBg)
        CImGui.c_set!(style.Colors, CImGui.ImGuiCol_WindowBg, ImVec4(col.x, col.y, col.z, 1.0f0))
    end

    # create texture for image drawing
    img_width, img_height = 500, 500
    image_id = nothing

    ENV["GKS_WSTYPE"] = "100"
    image = rand(GL.GLubyte, 4, img_width, img_height)
    mem = Printf.@sprintf("%p",pointer(image))
    conid = Printf.@sprintf("!%dx%d@%s.mem",  img_width, img_height, mem[3:end])

    clear_color = Cfloat[0.45, 0.55, 0.60, 1.00]
    image_id = nothing

    CImGui.render(ctx; engine, clear_color=Ref(clear_color)) do
        @cstatic phi = Cfloat(0.0) begin
            CImGui.Begin("GR Demo")
            if isnothing(image_id)
                image_id = CImGui.create_image_texture(img_width, img_height)
            end

            @c CImGui.SliderFloat("Angle", &phi, 0, 360, "%.4f")

            size = CImGui.GetWindowSize()
            canvas = CImGui.GetWindowPos()
            mouse_x = unsafe_load(CImGui.GetIO().MousePos.x)
            mouse_y = unsafe_load(CImGui.GetIO().MousePos.y)
            x = (mouse_x - canvas.x) / size.x
            y = 1 - (mouse_y - canvas.y) / size.y
            if 0 <= x <= 1 && 0 <= y <= 1
                @c CImGui.Text("($(round(x, digits=4)), $(round(y, digits=4)))")
            end
            CImGui.SetCursorPos((0, 0))

            beginprint(conid)
            draw(phi * π/180)
            endprint()

            CImGui.update_image_texture(image_id, image, img_width, img_height)
            CImGui.Image(image_id, CImGui.ImVec2(img_width, img_height))
            CImGui.End()
        end
    end
end

# Run automatically if the script is launched from the command-line
if !isempty(Base.PROGRAM_FILE)
    gr_demo()
end
