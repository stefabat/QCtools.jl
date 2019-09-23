
module QCtools

using DelimitedFiles
using LinearAlgebra
using DataStructures: OrderedDict

export readxyz,countbonds
export extrapolate_halkier,extrapolate_jensen,extrapolate_feller

export toev,tomev,tocm,tohz,tokj,tokcal,toang,tobohr,au2cgs
export cnt_diameter

# defining unit conversion constants as in MOLPRO
toev   = 27.2113839
tomev  = 27211.3839
tocm   = 219474.63067
tohz   = 6.5796839207
tokj   = 2625.500
tokcal = 627.5096
toang  = 0.529177209
tobohr = 1.889726131

# convert polarizability from atomic units to Ang^3
au2cgs = 16.48778/(4*pi*8.854188)

"""Compute the diameter of a CNT(n,m)"""
function cnt_diameter(n::Int, m::Int) 
    if n < m || n < 1 || m < 0
        throw(DomainError())
    end
    diam = 2.46/pi * sqrt(n*n + n*m + m*m)
    println(round(diam;digits=2)," Å")
    return diam
end

"Parse xyz file"
function readxyz(filename)
    f = open(filename,"r")
    natoms = parse(Int,readline(f))
    atoms = readdlm(f,skipstart=1)
    close(f)
    if natoms != size(atoms,1)
        throw(ArgumentError("number of atoms listed doesn't match with the number declared!"))
    end
    types  = convert(Array{String,1}, atoms[:,1])
    coords = convert(Array{Float64,2}, atoms[:,2:end])

    return types,coords
end


"Atomic covalent radii taken from http://periodictable.com"
cov_radii = Dict("H" =>0.31,"He"=>0.28,"Li"=>1.28,"Be"=>0.96,"B" =>0.85,
                 "C" =>0.76,"N" =>0.71,"O" =>0.66,"F" =>0.57,"Ne"=>0.58)

"Count number of bonds in molecule"
function countbonds(types, coords, delta = 0.25)
    n = length(types)
    bonds = OrderedDict{Tuple{Int64,Int64},Float64}()
    for i = 1:n-1
        for j = i+1:n
            d = norm(coords[i,:] - coords[j,:])
            if d < cov_radii[types[i]] + cov_radii[types[j]] + delta
                push!(bonds,(i,j)=>d)
            end
        end
    end
    return bonds
end

"""
Extrapolation to the complete basis set limit of one-electron properties
oep_x: value with basis set quality x
oep_y: value with basis set quality y = x-1
x:     max angular moment function
For details: Halkier et al., CPL, 289, 243 (1998)
"""
function extrapolate_halkier(oep_x, oep_y, x)
  return ( (oep_x * x^3) - (oep_y * (x-1)^2) ) / ( x^3 - (x-1)^3 )
end

"""
Extrapolation to the complete basis set limit of one-electron properties
oep_x: value with basis set quality x
oep_y: value with basis set quality y = x-1
x:     max angular moment function
For details: F. Jensen, Introduction to Computational Chemistry
                        3rd edition (2017)
"""
function extrapolate_jensen(oep_x, oep_y, x, y, B)
  @assert(y-x == 1)
  return ( exp(B*sqrt(x))*oep_x - exp(B*sqrt(y))*oep_y ) / ( exp(B*sqrt(x)) - exp(B*sqrt(y)) )
end

"p[1] is the CBS limit, p[2]=A and p[3]=B"
function extrapolate_feller(x, p)
  return p[1] + p[2]*exp(-sqrt(x).*p[3])
end

end
