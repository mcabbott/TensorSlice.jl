
"""
    @pretty @cast A[...] := B[...]

Prints an approximately equivalent expression with the macro expanded.
Compared to `@macroexpand1`, generated symbols are replaced with animal names (from MacroTools),
comments are deleted, module names are removed from functions,
and the final expression is fed to `println()`.

To copy and run the printed expression, you may need various functions which aren't exported.
Try something like `using TensorCast: orient, star, rview, @assert_, red_glue, sliceview`
"""
macro pretty(ex)
    if @capture(ex, @cast_str str_)
        full = "@cast " * cast_string(str)
        println("# " * full)
        return :(@pretty $(Meta.parse(full)) )

    elseif @capture(ex, @reduce_str str_)
        full = reduce_string(str)
        println("# " * full)
        return :(@pretty $(Meta.parse(full)) )

    elseif @capture(ex, @matmul_str str_)
        full = matmul_string(str)
        println("# " * full)
        return :(@pretty $(Meta.parse(full)) )

    else
        :( macroexpand($(__module__), $(ex,)[1], recursive=false) |> pretty |> println )
    end
end

function pretty(ex::Union{Expr,Symbol})
    ex = MacroTools.alias_gensyms(ex) # animal names
    ex = MacroTools.striplines(ex)    # remove line references
    ex = MacroTools.postwalk(ex) do x # remove esc()
        (x isa Expr && x.head == :escape && length(x.args) == 1) ? x.args[1] : x
    end
    pretty(string(ex))
end

function pretty(str::String)
    str = replace(str, r"\n(\s+\n)" => "\n")      # remove empty lines

    str = replace(str, r"\w+\.var\"(@\w+)\"" => s"\1")   # Julia 1.3, deal with e.g. Strided.var"@strided"

    str = replace(str, r"\w+\.(\w+)\(" => s"\1(") # remove module names on functions
    str = replace(str, r"\w+\.(\w+)!\(" => s"\1!(")
    str = replace(str, r"\w+\.(@\w+)" => s"\1")   # and on macros
    str = replace(str, r"\w+\.(\w+){" => s"\1{")  # and on structs...

    str = replace(str, "Colon()" => ":")
    str = replace(str, r"\$\(QuoteNode\((\d+)\)\)" => s":\1")
    str = replace(str, r"for (\w+) = " => s"for \1 in ")
end

pretty(tup::Tuple) = pretty(string(tup))

pretty(vec::Vector) = pretty(join(something.(vec, "nothing"), ", ")) # for indices, [i,j,k]
pretty(many...) = pretty(join(something.(many, "nothing"), ""))      # for unparse, no commas

pretty(x) = string(x)

function unparse(str::String, exs...)
    @capture(exs[1], left_ = right_ ) && return pretty(str, " ", left, " = ", right, "  ", join(exs[2:end],"  "))
    @capture(exs[1], left_ := right_ ) && return pretty(str, " ", left, " := ", right, "  ", join(exs[2:end],"  "))
    @capture(exs[1], left_ |= right_ ) && return pretty(str, " ", left, " |= ", right, "  ", join(exs[2:end],"  "))

    @capture(exs[1], left_ += right_ ) && return pretty(str, " ", left, " += ", right, "  ", join(exs[2:end],"  "))
    @capture(exs[1], left_ -= right_ ) && return pretty(str, " ", left, " -= ", right, "  ", join(exs[2:end],"  "))
    @capture(exs[1], left_ *= right_ ) && return pretty(str, " ", left, " *= ", right, "  ", join(exs[2:end],"  "))

    @capture(exs[1], red_(ind__) ) && return pretty(str, " ", join(exs,"  "))

    return pretty(exs)
end
