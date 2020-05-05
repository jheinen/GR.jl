using GR

const hello = Dict(
    "Chinese" => "你好世界",
    "Dutch" => "Hallo wereld",
    "English" => "Hello world",
    "French" => "Bonjour monde",
    "German" => "Hallo Welt",
    "Greek" => "γειά σου κόσμος",
    "Italian" => "Ciao mondo",
    "Japanese" => "こんにちは世界",
    "Korean" => "여보세요 세계",
    "Portuguese" => "Olá mundo",
    "Russian" => "Здравствуй, мир",
    "Spanish" => "Hola mundo"
)

function say_hello()
    y = 0.9
    for (lang, trans) in hello
        text(0.1, y, lang)
        text(0.4, y, trans)
        y -= 0.072
    end
    updatews()
end

say_hello()
