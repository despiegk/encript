import snappy
import md5
import os
import osproc
import strutils
import tables

var
    chunkmap = initTable[string, string]()
    finalhash = ""

proc calculateMD5Incremental(filename: string) : string =

    const blockSize: int = 10 * 1024
    var
        c1: MD5Context
        d1: MD5Digest
        c2: MD5Context
        d2: MD5Digest
        f: File
        bytesRead: int = 0
        buffer: array[blockSize, char]
        byteTotal: int = 0

    # read chunk of file, calling update until all bytes have been read
    try:
        f = open(filename)

        md5Init(c1)
        bytesRead = f.readBuffer(buffer.addr, blockSize)

        while bytesRead > 0:
            md5Init(c2)
            byteTotal += bytesRead
            md5Update(c1, buffer, bytesRead)
            md5Update(c2, buffer, bytesRead)
            md5Final(c2, d2)
            var hash = compress($d2)
            var output = execProcess("echo '" & hash & "' | ipfs add -n")
            var hashb = splitWhitespace(output)[8]
            chunkmap[$d2] = $hashb
            bytesRead = f.readBuffer(buffer.addr, blockSize)
        md5Final(c1, d1)

    except IOError:
        echo("File not found.")
    finally:
        if f != nil:
            close(f)

    finalhash = $d1

if paramCount() > 0:
    let arguments = commandLineParams()
    echo("MD5: ", calculateMD5Incremental(arguments[0]))
    echo finalhash
else:
    echo("Must pass filename.")
    quit(-1)