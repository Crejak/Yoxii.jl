module TestUtils

export compare_unsorted

function compare_unsorted(a::Vector{T}, b::Vector{T}) where {T}
    if length(a) != length(b)
        return false
    end
    
    freq_a = Dict{T, Int}()
    for elem in a
        freq_a[elem] = get(freq_a, elem, 0) + 1
    end
    
    for elem in b
        if !haskey(freq_a, elem)
            return false
        end
        
        freq_a[elem] -= 1
        if freq_a[elem] < 0
            return false
        end
    end
    
    return true
end

end