# License is MIT: LICENSE.md

using StrAPI, CharSetEncodings
@using_list StrAPI           api_ext api_def dev_ext dev_def
@using_list CharSetEncodings api_ext api_def dev_def

@static V6_COMPAT ? (using Base.Test) : (using Test)

@testset "CharSet" begin
    for CS in charset_types
        @test CS <: CharSet
    end
end

@testset "Encoding" begin
    for E in encoding_types
        @test E <: Encoding
    end
end

@testset "Character Set Encodings" begin
    for CS in cse_types
        @test CS <: CSE
        @test charset(CS)  <: CharSet
        @test encoding(CS) <: Encoding
    end
end
