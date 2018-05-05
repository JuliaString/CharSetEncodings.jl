__precompile__(true)
"""
Support for Character Sets, Encodings, and Character Set Encodings

Copyright 2017-2018 Gandalf Software, Inc., Scott P. Jones,
and other contributors to the Julia language
Licensed under MIT License, see LICENSE.md

Encodings inspired from collaborations on the following packages:
[Strings](https://github.com/quinnj/Strings.jl) with @quinnj (Jacob Quinn)
[StringEncodings](https://github.com/nalimilan/StringEncodings.jl) with @nalimilan (Milan Bouchet-Valat)
"""
module CharSetEncodings

const V6_COMPAT = VERSION < v"0.7.0-DEV"

export CSE, CharSet, Encoding, cse, charset, encoding, basecse, MaybeSub
export @cs_str, @enc_str, @cse
export BIG_ENDIAN, LITTLE_ENDIAN
export symstr, quotesym, V6_COMPAT
export CodeUnitTypes, CharSets, Encodings, CSEs

# Note: the generated *CSE, *CharSet and *Encoding names are also exported

import Base: promote_rule, show, print

symstr(s...) = Symbol(string(s...))
quotesym(s...) = Expr(:quote, symstr(s...))

const BIG_ENDIAN    = (ENDIAN_BOM == 0x01020304)
const LITTLE_ENDIAN = !BIG_ENDIAN

struct CharSet{CS}   end
struct Encoding{Enc} end
struct CSE{CS, ENC}  end

"""List of installed character sets"""
const CharSets  = CharSet[]

"""List of installed encodings"""
const Encodings = Encodings[]

"""List of installed character set encodings"""
const CSEs      = CSEs[]

CharSet(s)  = CharSet{Symbol(s)}()
Encoding(s) = Encoding{Symbol(s)}()
CSE(cs, e)  = CSE{CharSet(cs), Encoding(e)}()

macro cs_str(s)
    :(CharSet{$(quotesym(s))}())
end
macro enc_str(s)
    :(Encoding{$(quotesym(s))}())
end
macro cse(cs, e)
    :(CSE{CharSet{$(quotesym(cs)), $(quotesym(e))}()})
end

const MaybeSub{T} = Union{T, SubString{T}} where {T<:AbstractString}

# Define symbols used for characters, codesets, codepoints

const _cpname1 =
    [:Text1,   # Unknown character set, 1 byte
     :ASCII,   # (7-bit subset of Unicode)
     :Latin]   # ISO-8859-1 (8-bit subset of Unicode)
const _cpname2 =
    [:Text2,   # Unknown character set, 2 byte
     :UCS2]    # BMP (16-bit subset of Unicode)
const _cpname4 =
    [:Text4,   # Unknown character set, 4 byte
     :UTF32]   # corresponding to codepoints (0-0xd7ff, 0xe000-0x10fff)
const _subsetnam =
    [:_Latin,  # Latin subset of Unicode (0-0xff)
     :_UCS2,   # UCS-2 Subset of Unicode (0-0xd7ff, 0xe000-0xffff)
     :_UTF32]  # Full validated UTF-32
const _mbwname =
    [:UTF8,    # Validated UTF-8
     :UTF16]   # Validated UTF-16
const _binname =
    [:Binary]  # really, no character set at all, not text
const _rawname =
    [:UniPlus] # Unicode, plus invalid sequences (for String)

# List of basic character sets
const _charsets = vcat(_cpname1, _cpname2, _cpname4)

for nam in vcat(_charsets, _binname, _rawname)
    charset = symstr(nam, "CharSet")
    @eval const $charset = CharSet{$(quotesym(nam))}
    @eval export $charset
    @eval push!(CharSets, $charset)
end

# These are to indicate string types that must have at least one character of the type,
# for the internal types to make up the UniStr union type

const LatinSubSet  = CharSet{:LatinSubSet} # Has at least 1 character > 0x7f, all <= 0xff
const UCS2SubSet   = CharSet{:UCS2SubSet}  # Has at least 1 character > 0xff, all <= 0xffff
const UTF32SubSet  = CharSet{:UTF32SubSet} # Has at least 1 non-BMP character in string

push!(CharSets, LatinSubSet, UCS2SubSet, UTF32SubSet)

const Native1Byte  = Encoding(:Byte)
const UTF8Encoding = Encoding(:UTF8)
show(io::IO, ::Type{UTF8Encoding}) = print(io, "UTF-8")
show(io::IO, ::Type{Native1Byte})  = print(io, "8-bit")

export Native1Byte, UTF8Encoding

push!(Encodings, Native1Byte, UTF8Encoding)

# Allow handling different endian encodings

for (n, l, b, s) in (("2Byte", :LE2, :BE2, "16-bit"),
                     ("4Byte", :LE4, :BE4, "32-bit"),
                     ("UTF16", :UTF16LE, :UTF16BE, "UTF-16"))
    nat, swp = BIG_ENDIAN ? (b, l) : (l, b)
    natnam = symstr("Native",  n)
    swpnam = symstr("Swapped", n)
    @eval export $nat, $swp
    @eval const $natnam = Encoding($(quotesym("N", n)))
    @eval const $swpnam = Encoding($(quotesym("S", n)))
    @eval const $nat = $natnam
    @eval const $swp = $swpnam
    @eval show(io::IO, ::Type{$natnam}) = print(io, $s)
    @eval show(io::IO, ::Type{$swpnam}) = print(io, $(string(s, " ", BIG_ENDIAN ? "LE" : "BE")))
    @eval push!(Encodings, $natnam, $swpnam)
end

const _CSE{U} = Union{CharSet{U}, Encoding{U}} where {U}

print(io::IO, ::S) where {S<:_CSE{U}} where {U} = print(io, U)

show(io::IO, ::Type{CharSet{S}}) where {S}   = print(io, "CharSet{:", string(S), "}")
show(io::IO, ::Type{Encoding{S}}) where {S}  = print(io, "Encoding{:", string(S), "}")
show(io::IO, ::Type{CSE{CS,E}}) where {S,T,CS<:CharSet{S},E<:Encoding{T}} =
    print(io, "CSE{", string(S), ", ", string(T), "}")
print(io::IO, ::T) where {S,U,CS<:CharSet{S},E<:Encoding{U},T<:CSE{CS,E}} =
    (show(io, T); print(io, "()"))

const CodeUnitTypes = Union{UInt8, UInt16, UInt32}

# Definition of built-in CSEs (Character Set Encodings)

for (cs, enc) in ((vcat(_cpname1, :LatinSubSet, _binname), Native1Byte),
                  (vcat(_cpname2, :UCS2SubSet),            Native2Byte),
                  (vcat(_cpname4, :UTF32SubSet),           Native4Byte)),
    nam in cs
    csenam = symstr(nam, "CSE")
    @eval const $csenam = CSE{$(symstr(nam, "CharSet")), $enc}
    @eval push!(CSEs, $csenam)
end
const UTF8CSE   = CSE{UTF32CharSet, UTF8Encoding}
const UTF16CSE  = CSE{UTF32CharSet, NativeUTF16}

# Make wrappers for String type, this can help to be able to make (hashed) SubStr's of Strings
const RawUTF8CSE = CSE{UniPlusCharSet, UTF8Encoding}
show(io::IO, ::Type{RawUTF8CSE}) = print(io, :RawUTF8CSE)

export UTF8CSE, UTF16CSE, RawUTF8CSE
push!(CSEs, UTF8CSE, UTF16CSE, RawUTF8CSE)

for nam in vcat(_charsets, _subsetnam, _mbwname, _binname)
    str = String(nam)
    cse = symstr(nam, "CSE")
    @eval show(io::IO, ::Type{$cse}) = print(io, $(quotesym(cse)))
    str[1] == '_' || @eval export $cse
end

# Various useful groups of character set types

# These should be done via traits
const Binary_CSEs   = Union{Text1CSE, BinaryCSE}
const Latin_CSEs    = Union{LatinCSE, _LatinCSE}
const UTF8_CSEs     = Union{UTF8CSE,  RawUTF8CSE}
const UCS2_CSEs     = Union{UCS2CSE,  _UCS2CSE}
const UTF32_CSEs    = Union{UTF32CSE, _UTF32CSE}
const SubSet_CSEs   = Union{_LatinCSE, _UCS2CSE, _UTF32CSE}

const Byte_CSEs     = Union{ASCIICSE, Binary_CSEs, Latin_CSEs, UTF8_CSEs} # 8-bit code units
const Word_CSEs     = Union{Text2CSE, UCS2CSE, _UCS2CSE, UTF16CSE} # 16-bit code units
const Quad_CSEs     = Union{Text4CSE, UTF32CSE, _UTF32CSE}         # 32-bit code units

if !isdefined(Base, :codeunit)
    """Default value for Str /Chr types"""
    function codeunit end
    export codeunit
end

codeunit(::Type{<:CSE}) = UInt8
codeunit(::Type{<:Word_CSEs}) = UInt16
codeunit(::Type{<:Quad_CSEs}) = UInt32

"""Get the character set / encoding used by a string type"""
function cse end

cse(::Type{<:AbstractString}) = RawUTF8CSE     # allows invalid sequences
cse(str::AbstractString) = cse(typeof(str))
cse(::Type{<:SubString{T}}) where {T} = basecse(T)

"""Get the base cse (i.e. not a subset cse)"""
basecse(::Type{C}) where {C<:CSE} = C
basecse(::Type{_LatinCSE}) = LatinCSE
basecse(::Type{_UCS2CSE})  = UCS2CSE
basecse(::Type{_UTF32CSE}) = UTF32CSE

basecse(::Type{T}) where {<:AbstractString} = basecse(cse(T))

"""Get the character set used by a string type"""
function charset end

# Handle a few quirks
charset(::Type{<:AbstractChar}) = UTF32CharSet
charset(::Type{UInt8})          = BinaryCharSet  # UInt8 instead of "BinaryChr"
charset(::Type{Char})           = UniPlusCharSet # Char instead of "UniPlusChr"

charset(::Type{T}) where {T<:AbstractString} = charset(cse(T)) # Default unless overridden
charset(::Type{C}) where {CS,C<:CSE{CS}} = CS
charset(str::AbstractString) = charset(cse(str))

"""Get the encoding used by a string type"""
function encoding end

encoding(::Type{T}) where {T<:AbstractString} = encoding(cse(T)) # Default unless overridden
encoding(::Type{C}) where {CS,E,C<:CSE{CS,E}} = E
encoding(str::AbstractString) = encoding(cse(str))

# Promotion rules for character set encodings

promote_rule(::Type{Text2CSE}, ::Type{Text1CSE}) = Text2CSE
promote_rule(::Type{Text4CSE}, ::Type{Text1CSE}) = Text4CSE
promote_rule(::Type{Text4CSE}, ::Type{Text2CSE}) = Text4CSE

promote_rule(::Type{T}, ::Type{ASCIICSE}) where {T<:CSE} = T
promote_rule(::Type{T}, ::Type{<:Latin_CSEs}
             ) where {T<:Union{UTF8CSE,UTF16CSE,UCS2_CSEs,UTF32_CSEs}} = T

promote_rule(::Type{T}, ::Type{_LatinCSE}) where {T<:Union{ASCIICSE,LatinCSE}} = LatinCSE

promote_rule(::Type{T}, ::Type{_UCS2CSE}) where {T<:Union{ASCIICSE,Latin_CSEs,UCS2CSE}} = UCS2CSE
promote_rule(::Type{T}, ::Type{_UTF32CSE}) where {T<:CSE} = UTF32CSE
promote_rule(::Type{T}, ::Type{UTF32CSE}) where {T<:UCS2_CSEs} = UTF32CSE

end # module CharSetEncodings
