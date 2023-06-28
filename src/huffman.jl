using DataStructures

export encode_huffman, decode_huffman

struct Node
    sym::Union{Char, Nothing}
    left::Union{Node, Nothing}
    right::Union{Node, Nothing}
end
Node(s::Char) = Node(s, nothing, nothing) # leaf constructor 
Node(l::Node, r::Node) = Node(nothing, l, r) # merge constructor
Node(n::Node) = Node(n.sym, n.left, n.right) # copy constructor

"Builds a sorted array containing the frequencies of characters in the input string."
function getfreqs(str::String)
    charfreqs = PriorityQueue{Char, Int64}(Base.Order.Reverse, [])
    for c in str
        # adds in c as a key if it doesn't exist
        count = get!(charfreqs, c, 0)
        # two dict accesses per loop
        charfreqs[c] = count + 1
    end
    return collect(charfreqs)
end

"Helper function; selects the smallest element from the PriorityQueue of nodes and the reverse sorted array from readfile()."
function selectsmallest(nodes, queue)
    if isempty(queue)
        # nodes shouldn't be empty in this case
        # alert: something's wrong with my installation of DataStructures, since i'm getting old code fsr
        dequeue_pair!(nodes)
    elseif isempty(nodes)
        # first run, queue shouldn't be empty
        pop!(queue)
    else
        freq_node = peek(nodes)[2]
        freq_q = last(queue)[2]
        freq_q < freq_node ? pop!(queue) : dequeue_pair!(nodes)
    end
end

"Builds and returns the Huffman tree given a priority queue of characters. Frequency information is not retained."
function buildtree(queue)
    nodes = PriorityQueue{Node, Int64}([])
    while (!isempty(queue) || length(nodes) != 1)
        # select two smallest elements off both collections
        # smallest in a reverse ordered vector is last() and pop!(), which seems to be fast in Julia
        lc = selectsmallest(nodes, queue)
        rc = selectsmallest(nodes, queue)
        # copy constructor is used here if lc or rc are Nodes (popped from nodes)
        push!(nodes, Node(Node(lc[1]), Node(rc[1])) => lc[2] + rc[2]) 
    end
    return peek(nodes)[1]
end

"Gets the Huffman coding for a particular Huffman tree."
function getcode(tree::Node)
    dict = Dict{Char, BitArray}()
    # recursively build the dict
    getcode(tree, dict, BitArray([])) 
    return dict
end

function getcode(subtree::Node, dict::Dict, prefix::BitArray)
    if subtree.sym !== nothing # leaf Node
        push!(dict, subtree.sym => prefix)
    else # non-leaf node
        # [x; y] syntax equiv to vcat(x, y)
        getcode(subtree.left, dict, [prefix; BitArray([0])])
        getcode(subtree.right, dict, [prefix; BitArray([1])])
    end
end

# concatenate operations are very expensive
# encode(msg::String, code::Dict{Char, BitArray}) = reduce(msg, init=BitArray([])) do c1, c2
#     [c1; code[c2]]
# end

"Encodes a message with the given character-wise encoding."
function encode(msg::String, code::Dict{Char, BitArray})
    init = BitArray([])
    for c in msg
        bits = code[c]
        for b in bits
            push!(init, b)
        end
    end
    return init
end

"Returns a 4-byte codepoint describing the input UTF-32 character."
function getbytes(c::Char)
    xs = BitArray([])
    # bitstring always returns a 32 bit length string
    for bit in bitstring(c)
        bit == '0' ? push!(xs, 0) : push!(xs, 1)
    end
    return xs
end

"Encodes a message into binary with a Huffman encoding. Returns the tree and encoded message."
function encode_huffman(filemsg::String)
    tree = buildtree(getfreqs(filemsg))
    return (tree, encode(filemsg, getcode(tree)))
end

"Takes a Huffman coding tree and a coded message, and restores the original message."
function decode_huffman(coder::Node, coded_message::BitArray)
    # set the pointer to the head node
    sentinel = coder
    # string concatenation is expensive, so we build a char array instead
    message = Char[]
    for bit in coded_message
        # if bit is 0, go left, if bit is 1, go right
        sentinel = bit == 0 ? sentinel.left : sentinel.right
        # when we hit a leaf, append that character and reset
        # leaf nodes have non-nothing symbols & no children
        if sentinel.sym !== nothing
            push!(message, sentinel.sym)
            sentinel = coder
        end
    end
    # convert back to string
    return String(message)
end
#= For now, we'll directly serialize the tree
#  Tests suggest that serializing the tree is only ~2.7 times worse than
#  compressing it, and that serializing the code is ~4.5 times worse than
#  the compressed tree

"Encodes a non-canonical Huffman tree as a BitArray."
function encodeTree(tree::Node)
    arr = BitArray([])
    # pass by reference enables modification of the arr
    encodeTree(arr, tree)
    return arr
end

function encodeTree(arr::BitArray, tree::Node)
    if tree.sym !== nothing
        push!(arr, 0)
        append!(arr, getbytes(tree.sym))
    else # internal node
        push!(arr, 1)
        encodeTree(arr, tree.left)
        encodeTree(arr, tree.right)
    end
end

function decodeTree(bits::BitArray)
    iter = Iterators.Stateful(bits)
    return decodeTree(iter)
end

# nonfunctional
function decodeTree(iter::Base.Stateful)
    try
        nodebit = popfirst!(iter)
        if nodebit == 1
            # read in 32 bits and convert to a char
            charint = 0
            for i in 1:32
                charint += popfirst!(iter)
            end
            return Node(Char(charint))
        else
            leftchild = decodeTree(iter)
            rightchild = decodeTree(iter)
            return Node(leftchild, rightchild)
        end
    catch error
        return error != EOFError() ? throw(error) : nothing
    end
end
=#