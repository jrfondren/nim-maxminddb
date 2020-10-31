import maxminddb/[node, reader, errors]
from iputils import IPv4, IPv6

const
  metadataMarker = "\xAB\xCD\xEFMaxMind.com"
  metadataMaxSize = 128 * 1024
  dataSeparator = 16'u32
type
  Metadata* = object
    nodeCount*: uint32
    recordSize*: uint16
    ipVersion*: uint16
    databaseType*: string
    languages*: seq[string]
    version*: tuple[major: uint16, minor: uint16]
  MaxMindDB* = object
    data: string
    reader*: Reader
    metadata*: Metadata
  DatabaseNode* = ref object
    left*, right*: uint32

proc findMetadata*(db: openArray[char]): int =
  var pos = db.len - metadataMarker.len - 1
  let minpos = max(0, db.len - metadataMaxSize)
  while pos > minpos:
    if db.toOpenArray(pos, pos+metadataMarker.len-1) == metadataMarker:
      return pos + metadataMarker.len
    else:
      pos.dec
  raise newException(BadMaxmindDatabaseError, "Unable to find MaxMind v2 metadata marker")

proc initMetadata(node: Node): Metadata =
  return Metadata(
    nodeCount: node.mapGet[:uint32]("node_count"),
    recordSize: node.mapGet[:uint16]("record_size"),
    ipVersion: node.mapGet[:uint16]("ip_version"),
    databaseType: node.mapGet[:string]("database_type"),
    languages: node.mapGet[:seq[string]]("languages"),
    version: (
      node.mapGet[:uint16]("binary_format_major_version"),
      node.mapGet[:uint16]("binary_format_minor_version")))

proc nodeSize*(m: Metadata): int = int(m.recordSize.int / 4)
proc dataSize*(m: Metadata): int = m.nodeSize * m.nodeCount.int

proc initMetadata*(db: string): Metadata =
  let start = findMetaData(db)
  var reader = initReader(db, start)
  return initMetadata(reader.readNode)

proc initMaxMind*(db: string): MaxMindDB =
  let md = initMetadata(db)
  return MaxMindDB(data: db, reader: initReader(db[md.dataSize + dataSeparator.int .. db.len-1]), metadata: md)

func readSlice*(slice: openArray[char]): uint32 =
  for b in slice:
    result *= 256
    result += b.uint32

proc initDatabaseNode*(slice: string): DatabaseNode =
  case slice.len
  of 6:
    return DatabaseNode(
      left: readSlice(slice.toOpenArray(0, 3-1)),
      right: readSlice(slice.toOpenArray(3, 6-1)))
  of 7:
    return DatabaseNode(
      left: readSlice(slice.toOpenArray(0, 3-1)) + ((slice[3].uint32 and 0xF0) shl 20),
      right: readSlice(slice.toOpenArray(4, 7-1)) + ((slice[3].uint32 and 0x0F) shl 24))
  of 8:
    return DatabaseNode(
      left: readSlice(slice.toOpenArray(0, 4-1)),
      right: readSlice(slice.toOpenArray(4, 8-1)))
  else:
    assert(false, "attempted to decode invalid slice; slice length must be 24, 28, or 32 bits")

proc getNodeAt*(db: MaxMindDB, pos: int): DatabaseNode =
  let nodeSize = db.metadata.nodeSize
  let offset = pos * nodeSize
  return initDatabaseNode(db.data[offset ..< offset + nodeSize])

proc ipv4to6(ip: IPv4): IPv6 =
  copyMem(result[12].addr, ip[0].unsafeAddr, 4)

proc lookupImpl(db: MaxMindDB, ip: IPv4 | IPv6): Node =
  var node = db.getNodeAt(0)
  for octet in ip:
    var mask = 0b1000_0000'u8
    while mask != 0:
      var next =
        if (octet and mask) != 0: node.right
        else: node.left
      if next < db.metadata.nodeCount:
        node = db.getNodeAt(next.int)
      elif next == db.metadata.nodeCount:
        return nil
      else:
        next.dec int(db.metadata.nodeCount + dataSeparator)
        var reader = initReader(db.reader, next.int)
        return reader.readNode
      mask = mask shr 1

proc lookup*(db: MaxMindDB, ip: IPv4): Node =
  if db.metadata.ipVersion == 4: db.lookupImpl(ip)
  else: db.lookupImpl(ip.ipv4to6)

