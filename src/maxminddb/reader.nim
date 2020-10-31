import std/endians

type
  Reader* = object
    data*: string
    current*: int

proc initReader*(data: string, offset = 0): Reader =
  # #15746 # result = Reader(data: data, current: offset)
  result = Reader(data: "")
  result.data = data
  result.current = offset

proc initReader*(reader: Reader, offset = 0): Reader =
  # #15746 # result = Reader(data: reader.data, current: offset)
  result = Reader(data: "")
  result.data = reader.data
  result.current = offset

proc read*(this: var Reader, length: int): string =
  let start = this.current
  this.current.inc length
  result = this.data[start ..< this.current]

proc readVal*[T](this: var Reader, length: int): T =
  doAssert(length + this.current <= this.data.len)
  doAssert(length <= T.sizeof)
  if length == 0: return 0 # ???
  var readbuf: array[T.sizeof, char]
  copyMem(readbuf[readbuf.len - length].addr, this.data[this.current].addr, length)
  when cpuEndian == littleEndian:
    var buffer: array[T.sizeof, char]
    when T.sizeof == 8:
      swapEndian64(buffer[0].addr, readbuf[0].addr)
    elif T.sizeof == 4:
      swapEndian32(buffer[0].addr, readbuf[0].addr)
    elif T.sizeof == 2:
      swapEndian16(buffer[0].addr, readbuf[0].addr)
    elif T.sizeof == 1:
      buffer = readbuf
    else:
      assert(false, "unsupported type for readVal")
    result = cast[ptr UncheckedArray[T]](buffer[0].addr)[0]
  else:
    result = cast[ptr UncheckedArray[T]](readbuf[0].addr)[0]
  this.current.inc length

proc readValExtra*[T](this: var Reader, length: int, extrabits: T): T =
  return this.readVal[:T](length) + (extrabits shl (length * 8))

proc readByte*(this: var Reader): char =
  result = this.data[this.current]
  this.current.inc
