import std/unittest
import maxminddb

test "can find metadata":
  let database = readFile("testdata/test-data/MaxMind-DB-no-ipv4-search-tree.mmdb")
  check database.findMetadata == 421

suite "GeoIP2-Country-Test.mmdb as expected":
  let db = "testdata/test-data/GeoIP2-Country-Test.mmdb"
    .readFile
    .initMaxMind
  test "nodeCount":
    check db.metadata.nodeCount == 1651
  test "recordSize":
    check db.metadata.recordSize == 28
  test "ipVersion":
    check db.metadata.ipVersion == 6
  test "databaseType":
    check db.metadata.databaseType == "GeoIP2-Country"
  test "languages":
    check db.metadata.languages == ["en"]
  test "version number":
    check db.metadata.version.major == 2
