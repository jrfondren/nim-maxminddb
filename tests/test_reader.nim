{.experimental: "views".}
import std/unittest
import maxminddb/reader

let
  s1 = "\x00\x00\x00\x01"
  s2 = "\xaa\xbb\xcc\xdd"

suite "test reader.readVal[T]":
  test "read int32":
    var r = initReader(s1)
    check r.readVal[:int32](4) == 1
  test "read int16s":
    var r = initReader(s1)
    check r.readVal[:int16](2) == 0
    check r.readVal[:int16](2) == 1
  test "read bytes":
    var r = initReader(s1)
    check r.readVal[:byte](1) == 0
    check r.readVal[:byte](1) == 0
    check r.readVal[:byte](1) == 0
    check r.readVal[:byte](1) == 1
  test "read (1) bytes of int32":
    var r = initReader(s2)
    check r.readVal[:int32](1) == 0xAA
  test "read (2) bytes of int32":
    var r = initReader(s2)
    check r.readVal[:int32](2) == 0xAABB
  test "read (3) bytes of int32":
    var r = initReader(s2)
    check r.readVal[:int32](3) == 0xAABBCC
  test "read (4) bytes of int32":
    var r = initReader(s2)
    check r.readVal[:int32](4) == 0xAABBCCDD'i32
