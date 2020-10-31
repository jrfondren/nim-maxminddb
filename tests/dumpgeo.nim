import maxminddb, maxminddb/node
import std/[tables, strformat]
import iputils
import cligen

proc main(mmdb, ip: string) =
  let db = mmdb.readFile.initMaxMind
  let res = db.lookup(ip.parseIPv4)
  if res.isNil: quit &"Failed to find {ip} in {mmdb}" 
  else: echo res

when isMainModule:
  dispatch(main, help = {
    "mmdb": "The path to a MaxMindDB file, version 2",
    "ip": "an IP (versio 2), like 127.0.0.1",
  })
