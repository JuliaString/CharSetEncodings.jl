# Character Sets
#
# Copyright 2017-2018 Gandalf Software, Inc., Scott P. Jones
# Licensed under MIT License, see LICENSE.md

@api define_public  CharSet
@api define_develop charset_types

struct CharSet{CS}   end

"""List of installed character sets"""
const charset_types = []

CharSet(s)  = CharSet{Symbol(s)}()

# List of basic character sets

show(io::IO, ::Type{CharSet{S}}) where {S} = print(io, "CharSet{:", string(S), "}")

const UniPlusCharSet = CharSet{:UniPlus}
push!(charset_types, UniPlusCharSet)

@api define_public UniPlusCharSet

for lst in cse_info
    length(lst) > 2 && continue
    nam = lst[1]
    csnam = symstr(nam, "CharSet")
    @eval const $csnam = CharSet{$(quotesym(nam))}
    @eval show(io::IO, ::Type{$csnam}) = print(IO, $nam, "CharSet")
    @eval push!(charset_types, $csnam)
    @eval @api $(String(nam)[1] == '_' ? :define_develop : :define_public) $csnam
end

# Handle a few quirks
charset(::Type{<:AbstractChar}) = UTF32CharSet
charset(::Type{UInt8})          = BinaryCharSet  # UInt8 instead of "BinaryChr"
charset(::Type{Char})           = UniPlusCharSet # Char instead of "UniPlusChr"
