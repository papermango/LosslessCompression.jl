module LosslessCompression

using Serialization

export encodefile, decodefile

# Write your package code here.
include("huffman.jl")

function encodefile(filepath::String, output::String="", bwt=false)
    file_message = read(filepath, String)
    if output == filepath
        throw(ErrorException("Output file must have a different name than the input file."))
    end
    file_out = length(output) > 0 ? output * ".encjl" : filepath * ".encjl"
    serialize(file_out, encode_huffman(file_message))
end

function decodefile(filepath::String, output::String="")
    tree, encoded = deserialize(filepath)
    if output == filepath
        throw(ErrorException("Output file must have a different name than the input file."))
    end
    file_out = length(output) > 0 ? output : filepath[1:length(filepath) - 6] * ".out"
    write(file_out, decode_huffman(tree, encoded))
end

end