import std/unittest
import maxminddb

suite "test readSlice":
  test "read one byte":
    check readSlice("\x01") == 1
  test "read two bytes":
    check readSlice("\x01\x00") == 256
  test "read three bytes":
    check readSlice("\x01\x00\x00") == 65536
  test "read four bytes":
    check readSlice("\x01\x00\x00\x00") == 16777216

proc db(s: string): (uint32, uint32) =
  let n = initDatabaseNode(s)
  return (n.left, n.right)

suite "test initDatabaseNode":
  test "six bytes":
    check db("\x01\x02\x03\x04\x05\x06") == (66051'u32, 263430'u32)
    check db("\xFF\x02\x03\x04\x05\x06") == (16712195'u32, 263430'u32)
    check db("\x00\x02\x03\x04\x05\x06") == (515'u32, 263430'u32)
    check db("\x80\x02\x03\x04\x05\x06") == (8389123'u32, 263430'u32)
    check db("\x04\x05\x06\x01\x02\x03") == (263430'u32, 66051'u32)
    check db("\x04\x05\x06\xFF\x02\x03") == (263430'u32, 16712195'u32)
    check db("\x04\x05\x06\x00\x02\x03") == (263430'u32, 515'u32)
    check db("\x04\x05\x06\x80\x02\x03") == (263430'u32, 8389123'u32)
  test "seven bytes":
    check db("\xFF\x01\x02\x03\x04\x05\x06") == (16711938'u32, 50595078'u32)
    check db("\x00\x01\x02\x03\x04\x05\x06") == (258'u32, 50595078'u32)
    check db("\x80\x01\x02\x03\x04\x05\x06") == (8388866'u32, 50595078'u32)
    check db("\x01\x01\x02\x03\x04\x05\x06") == (65794'u32, 50595078'u32)
    check db("\x03\x04\x05\x06\xFF\x01\x02") == (197637'u32, 117375234'u32)
    check db("\x03\x04\x05\x06\x00\x01\x02") == (197637'u32, 100663554'u32)
    check db("\x04\x05\x06\x80\x01\x02\x03") == (134481158'u32, 66051'u32)
    check db("\x04\x05\x06\x01\x01\x02\x03") == (263430'u32, 16843267'u32)
  test "eight bytes":
    check db("\xFF\x01\x02\x03\x04\x05\x06\x07") == (4278256131'u32, 67438087'u32)
    check db("\x00\x01\x02\x03\x04\x05\x06\x07") == (66051'u32, 67438087'u32)
    check db("\x80\x01\x02\x03\x04\x05\x06\x07") == (2147549699'u32, 67438087'u32)
    check db("\x01\x01\x02\x03\x04\x05\x06\x07") == (16843267'u32, 67438087'u32)
