# nim-maxminddb
A reader library for MaxMind's GeoLite2 databases

## BIG WARNING
This is technically usable but in a very rough state, and not published to
nimble. It's really waiting on some fixes to Nim's experimental viewtypes to
cut down on copies of the MaxMind database content:

https://github.com/nim-lang/Nim/issues/15778 (showstopper)

https://github.com/nim-lang/Nim/issues/15746

## notes

It was surprisingly easy to rewrite away from viewtypes after I hit that first
bug; I expect it'll be just as easy to switch back to them after it's fixed.

## Testing
```
nimble test
nimble testmm    # run 'nimble fetchmm' first
nimble testlite  # get GeoLite2-Country.mmdb first from maxmind.com
```

### dump metadata
```
$ nim r --hints:off tests/dumpmeta.nim GeoLite2-Country.mmdb 
OK GeoLite2-Country.mmdb: (nodeCount: 637170, recordSize: 24, ipVersion: 6, databaseType: "GeoLite2-Country", languages: @["de", "en", "es", "fr", "ja", "pt-BR", "ru", "zh-CN"], version: (major: 2, minor: 0))
```

### dump IP lookup results
```
$ nim r --hints:off tests/dumpgeo.nim -m GeoLite2-Country.mmdb -i 1.1.1.1 | jq .country 
{
  "geoname_id": 2077456,
  "names": {
    "en": "Australia",
    "pt-BR": "Austrália",
    "ru": "Австралия",
    "fr": "Australie",
    "de": "Australien",
    "zh-CN": "澳大利亚",
    "es": "Australia",
    "ja": "オーストラリア"
  },
  "iso_code": "AU"
}
```
