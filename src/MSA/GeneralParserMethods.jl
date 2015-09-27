using MIToS.Utils

# Mappings
# ========

function _fill_aln_seq_ann!(aln, seq_ann::Vector{ASCIIString}, seq::Vector{UInt8}, init::Int, nres::Int, i)
  if length(seq) != nres
    throw(ErrorException(string("There is and aligned sequence with different number of columns [ ", length(seq), " != ", nres, " ]:\n", ascii(seq))))
  end
  @inbounds for j in 1:nres
    res = seq[j]
    aln[j,i] = Residue( res )
    if res != UInt8('-') && res != UInt8('.')
      seq_ann[j] = string(init)
      init += 1
    else
      seq_ann[j] = ""
    end
  end
  join(seq_ann, ',')
end

function _to_msa_mapping(sequences::Array{ASCIIString,1})
  nseq = size(sequences,1)
  nres = length(sequences[1])
  aln = Array(Residue,nres,nseq)
  mapp = Array(ASCIIString, nseq)
  seq_ann = Array(ASCIIString, nres)
  for i in 1:nseq
    mapp[i] = _fill_aln_seq_ann!(aln, seq_ann, sequences[i].data, 1, nres, i)
  end
  (aln', mapp)
end

function _to_msa_mapping(sequences::Array{ASCIIString,1}, ids::Array{ASCIIString,1})
  nseq = size(sequences,1)
  nres = length(sequences[1])
  aln = Array(Residue,nres,nseq)
  mapp = Array(ASCIIString, nseq)
  seq_ann = Array(ASCIIString, nres)
  sep = r"/|-"
  for i in 1:nseq
    fields = split(ids[i],sep)
    init = length(fields) == 3 ? parse(Int, fields[2]) : 1
    mapp[i] = _fill_aln_seq_ann!(aln, seq_ann, sequences[i].data, init, nres, i)
  end
  (aln', mapp)
end

# Delete Full of Gap Columns
# ==========================

"""Deletes columns with 100% gaps, this columns are generated by inserts."""
function deletefullgapcolumns!(msa::AbstractMultipleSequenceAlignment, annotate::Bool=true)
  mask = columngappercentage(msa) .!= one(Float64)
  number = sum(~mask)
  if number != 0
    annotate && annotate_modification!(msa, string("deletefullgaps!  :  Deletes ", number," columns full of gaps (inserts generate full gap columns on MIToS because lowercase and dots are not allowed)"))
    filtercolumns!(msa, mask, annotate)
  end
  msa
end

function deletefullgapcolumns(msa::Matrix{Residue})
  mask = columngappercentage(msa) .!= one(Float64)
  number = sum(~mask)
  if number != 0
    return(filtercolumns(msa, mask))
  end
  msa
end

@doc """`parse(io::Union{IO, AbstractString}, format[, output; generatemapping::Bool=false, useidcoordinates::Bool=false, deletefullgaps::Bool=true ])`

The keyword argument `generatemapping` (`false` by default) indicates if the mapping of the sequences ("SeqMap") and columns ("ColMap") should be generated and saved in the annotations.
If `useidcoordinates` is `true` (default: `false`) the sequence IDs of the form "ID/start-end" are parsed and used for determining the start and end positions when the mappings are generated.
`deletefullgaps` (`true` by default) indicates if columns 100% gaps (generally inserts from a HMM) must be removed from the MSA.""" parse
