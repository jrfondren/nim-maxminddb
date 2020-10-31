import reader, errors
import std/[tables, strformat, json]

type
  NodeKind* = enum
    Extended, Pointer, String, Double, Binary,
    Uint16, Uint32, Map, Int32, Uint64,
    Uint128, Array, CacheContainer, EndMarker, Boolean,
    Float
  Node* = ref object
    case kind*: NodeKind
    of CacheContainer, EndMarker: discard
    of Binary: binaryData*: string
    of String: stringData*: string
    of Double: doubleData*: float64
    of Uint16: uint16Data*: uint16
    of Uint32: uint32Data*: uint32
    of Int32: int32Data*: int32
    of Uint64: uint64Data*: uint64
    of Uint128: uint128Data*: string
    of Float: floatData*: float32
    of Boolean: boolData*: bool
    of Map: mapData*: Table[string, Node]
    of Array: arrayData*: seq[Node]
    of Pointer, Extended: discard

# debugging; escapeJson used for piping to jq
proc `$`*(node: Node): string =
  case node.kind
  of Binary: result = &"Binary(\"{node.binaryData.escapeJson}\")"
  of String: result = node.stringData.escapeJson
  of Double: result = &"{node.doubleData}"
  of Uint16: result = &"{node.uint16Data}"
  of Uint32: result = &"{node.uint32Data}"
  of Int32: result = &"{node.int32Data}"
  of Uint64: result = &"{node.uint64Data}"
  of Uint128: result = &"Uint128({node.uint128Data.escapeJson})"
  of Float: result = &"{node.floatData}"
  of Boolean: result = &"{node.boolData}"
  of Map:
    result = "{"
    for (key, val) in node.mapData.pairs:
      if result.len > 1:
        result &= ", "
      result &= &"{key.escapeJson}: {val}"
    result &= "}"
  of Array:
    case node.arrayData.len
    of 0: result = "[]"
    of 1: result = &"[{node.arrayData[0]}]"
    else:
      result = &"[{node.arrayData[0]}"
      for n in node.arrayData[1..^1]:
        result &= &", {n}"
      result &= "]"
  of CacheContainer: result = "[CC]"
  of EndMarker: result = "[EM]"
  of Pointer: result = "[**]"
  of Extended: result = "[++]"

proc get*[T](node: Node): T =
  case node.kind
  of Binary:
    when T is string: return node.binaryData
    else: assert(false, "invalid node type")
  of String:
    when T is string: return node.stringData
    else: assert(false, "invalid node type")
  of Double:
    when T is float64: return node.doubleData
    else: assert(false, "invalid node type")
  of Uint16:
    when T is uint16: return node.uint16Data
    else: assert(false, "invalid node type")
  of Uint32:
    when T is uint32: return node.uint32Data
    else: assert(false, "invalid node type")
  of Int32:
    when T is int32: return node.int32Data
    else: assert(false, "invalid node type")
  of Uint64:
    when T is uint64: return node.uint64data
    else: assert(false, "invalid node type")
  of Uint128:
    when T is string: return node.uint128Data
    else: assert(false, "invalid node type")
  of Float:
    when T is float32: return node.floatData
    else: assert(false, "invalid node type")
  of Boolean:
    when T is bool: return node.boolData
    else: assert(false, "invalid node type")
  of Map:
    when T is Table[string, Node]: return node.mapData
    else: assert(false, "invalid node type")
  of Array:
    when T is seq[Node]: return node.arrayData
    elif T is seq[string]:
      var a = newSeqOfCap[string](node.arrayData.len)
      for n in node.arrayData:
        a.add n.get[:string]
      return a
    else: assert(false, "invalid node type")
  of Pointer, Extended, CacheContainer, EndMarker: assert(false, "unimplemented")

proc mapGet*[T](node: Node, key: string): T =
  let map = node.get[:Table[string, Node]]
  map[key].get[:T]

proc readNode*(data: var Reader): Node

proc followPointer(data: var Reader, id: uint8): Node =
  let
    extrabits = id and 0b0000_0111
    jump: uint =
      case range[0..3]((id and 0b0001_1000) shr 3)
        of 0: data.readValExtra[:uint32](1, extrabits) + 0
        of 1: data.readValExtra[:uint32](2, extrabits) + 2048
        of 2: data.readValExtra[:uint32](3, extrabits) + 526336
        of 3: data.readVal[:uint32](4)
  var newdata = data.initReader(jump.int)
  result = newdata.readNode

proc readArray(data: var Reader, length: int): Node =
  result = Node(kind: NodeKind.Array, arrayData: newSeq[Node](length))
  for i in 0 ..< length:
    result.arrayData[i] = readNode(data)

proc readMap(data: var Reader, length: int): Node =
  result = Node(kind: NodeKind.Map, mapData: initTable[string, Node]())
  for _ in 0 ..< length:
    let
      key = data.readNode
      value = data.readNode
    case key.kind
    of String: result.mapData[key.stringData] = value
    else: assert(false, "Invalid map key: should be string")

proc readNode*(data: var Reader): Node =
  let
    id = data.readByte.uint8
    kind = block:
      var k: uint8 = (id and 0b1110_0000) shr 5
      if k == NodeKind.Pointer.uint8: return followPointer(data, id)
      elif k == NodeKind.Extended.uint8: k = data.readByte.uint8 + 7
      if k notin NodeKind.Extended.uint8 .. NodeKind.Float.uint8:
        raise newException(BadMaxmindDatabaseError, "Unexpected Node type -- not a version 2 database?")
      k.NodeKind
    payloadSize = block:
      var p: uint = id and 0b0001_1111
      if p >= 29:
        case range[29..31](p)
        of 29: p = readVal[uint](data, 1) + 29
        of 30: p = readVal[uint](data, 2) + 285
        of 31: p = readVal[uint](data, 3) + 65821
      p.int
  case kind
  of CacheContainer, EndMarker: assert(false, "Unimplemented maxminddb type")
  of Binary: return Node(kind: kind, binaryData: data.read(payloadSize))
  of String:
    let n = Node(kind: kind, stringData: data.read(payloadSize))
    return n
  of Double: return Node(kind: kind, doubleData: data.readVal[:float64](payloadSize))
  of Uint16: return Node(kind: kind, uint16Data: data.readVal[:uint16](payloadSize))
  of Uint32: return Node(kind: kind, uint32Data: data.readVal[:uint32](payloadSize))
  of Int32: return Node(kind: kind, int32Data: data.readVal[:int32](payloadSize))
  of Uint64: return Node(kind: kind, uint64Data: data.readVal[:uint64](payloadSize))
  of Uint128: return Node(kind: kind, uint128Data: data.read(payloadSize))
  of Float: return Node(kind: kind, floatData: data.readVal[:float32](payloadSize))
  of Boolean: return Node(kind: kind, boolData: payloadSize > 0)
  of Map: return readMap(data, payloadSize)
  of Array: return readArray(data, payloadSize)
  of Pointer, Extended: assert(false)
