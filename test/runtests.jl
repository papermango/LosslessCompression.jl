using LosslessCompression
using Test

@testset "Small files encoding/decoding" begin
    lorem_small = read("test_files/lorem_small.txt", String)
    tiny = read("test_files/tiny.txt", String)

    @test decode_huffman(encode_huffman(lorem_small)...) == lorem_small
    @test decode_huffman(encode_huffman(tiny)...) == tiny
end

@testset "Small files reading/writing, default output names" begin
    encodefile("test_files/lorem_small.txt")
    decodefile("test_files/lorem_small.txt.encjl")
    @test read("test_files/lorem_small.txt", String) == read("test_files/lorem_small.txt.out", String)

    encodefile("test_files/tiny.txt")
    decodefile("test_files/tiny.txt.encjl")
    @test read("test_files/tiny.txt", String) == read("test_files/tiny.txt.out", String)
end

@testset ">1KB files encoding/decoding" begin
    words_small = read("test_files/words_small.txt", String)
    @test decode_huffman(encode_huffman(words_small)...) == words_small
end

@testset ">1KB files reading/writing, custom output names" begin
    encodefile("test_files/words_small.txt", "test_files/squished_words_small")
    decodefile("test_files/squished_words_small.encjl", "test_files/unsquished_words_small.txt")
    @test read("test_files/words_small.txt", String) == read("test_files/unsquished_words_small.txt", String)
end