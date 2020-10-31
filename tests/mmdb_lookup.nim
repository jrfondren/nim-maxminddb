import std/[unittest, tables]
import maxminddb, maxminddb/node
import iputils

suite "MaxMind-DB-string-value-entries.mmdb":
  let database = "testdata/test-data/MaxMind-DB-string-value-entries.mmdb"
    .readFile
    .initMaxMind
  let res = database.lookup("1.1.1.1".parseIPv4)
  test "can find IP":
    check res != nil
  test "result is string":
    check res.kind == NodeKind.String
  test "result is IP":
    check res.get[:string] == "1.1.1.1/32"

suite "GeoIP2-Static-IP-Score-Test":
  let database = "testdata/test-data/GeoIP2-Static-IP-Score-Test.mmdb"
    .readFile
    .initMaxMind
  let res = database.lookup("1.1.1.1".parseIPv4)
  test "can find IP":
    check res != nil
  test "result is map":
    check res.kind == NodeKind.Map
  test "result has key of \"score\"":
    check "score" in res.mapData
  test "score is 0.01":
    check 0.01 == res.mapGet[:float]("score")
