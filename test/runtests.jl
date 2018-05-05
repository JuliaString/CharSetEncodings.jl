# License is MIT: LICENSE.md

using CharSetEncodings

@static V6_COMPAT ? (using Base.Test) : (using Test, Random, Unicode)

@testset "CharSet" begin
    for cs in CharSetEncodings._charsets
        @test "$(typeof(CharSet(cs)))" == "CharSet{:$(cs)}"
    end
    for CS in CharSets
        println(CS)
        @test charset(CS) isa CharSet
    end
end

@testset "Encoding" begin
    for E in Encodings
        println(E)
        @test encoding(E) isa Encoding
    end
end

@testset "Character Set Encodings" begin
    for CS in CSEs
        println(CS)
        @test cse(CS) isa CSE
    end
end
