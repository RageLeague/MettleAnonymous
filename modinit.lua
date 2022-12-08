local filepath = require "util/filepath"

local function OnLoad( mod )
    rawset(_G, "CURRENT_MOD_ID", mod.id)

    for k, filepath in ipairs( filepath.list_files( "MettleAnonymous:patches/", "*.lua", true )) do
        local name = filepath:match( "(.+)[.]lua$" )
        if name then
            require(name)
        end
    end
end

return {
    version = "0.0.1",
    alias = "MettleAnonymous",

    OnLoad = OnLoad,

    title = "Mettle Anonymous (Reverse Mettle Allocation)",
    description = "Addicted to mettle? This mod helps you quit. Reverse mettle upgrades you bought from Plundak.",
    previewImagePath = "preview.png",
}
