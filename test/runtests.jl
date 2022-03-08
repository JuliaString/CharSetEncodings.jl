# License is MIT: LICENSE.md

using ModuleInterfaceTools

@api test CharSetEncodings

@testset "CharSet" begin
    for CS in charset_types
        @test CS <: CharSet
        nam = sprint(show, CS)
        @test endswith(nam, "CharSet") || startswith(nam, "CharSet{:")
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

@testset "CSE promotions" begin
    for i = 1:length(cse_types), j = i+1:length(cse_types)
        c1 = cse_types[i]
        c2 = cse_types[j]
        c1 == c2 && continue
        @test promote_type(c1, c2) in cse_types
    end
end

@testset "show charsets" begin
    for CS in charset_types
    end
end
