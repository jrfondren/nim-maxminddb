import std/[unittest, tables]
import maxminddb, maxminddb/node
import iputils

let database = "GeoLite2-Country.mmdb"
  .readFile
  .initMaxMind
let res = database.lookup("1.1.1.1".parseIPv4)

suite "geolocate 1.1.1.1":
  test "can find IP":
    check res != nil
  test "result is map":
    check res.kind == NodeKind.Map
  test "result has country names table":
    check res.mapGet[:Table[string, Node]]("country")["names"] != nil
  test "country is Australia":
    check "Australia" == res.mapGet[:Table[string, Node]]("country")["names"].mapGet[:string]("en")
  test "iso_code is AU":
    check "AU" == res.mapGet[:Table[string, Node]]("country")["iso_code"].get[:string]
