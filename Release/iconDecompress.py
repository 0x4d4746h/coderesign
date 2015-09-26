#/var/folders/1p/w6nj201j2q7_f0rfswbbw9h80000gn/T/com.0x4d4746h.resign/Payload/UICatalog.app/Icon.png
from struct import *
from zlib import *
import stat
import sys
import os


def updatePNG(compressedFileName, newfileName):
    print ("[Python :]start to convert %s to %s " % (compressedFileName, newfileName))

    pngheader = "\x89PNG\r\n\x1a\n"
    file = open(compressedFileName, "rb")
    oldPNG = file.read()
    file.close()
    if oldPNG[:8] != pngheader:
        print "[Python :]pngheader is not match"
        return None
    newPNG = oldPNG[:8]
    
    chunkPos = len(newPNG)
    # For each chunk in the PNG file    
    while chunkPos < len(oldPNG):
        
        # Reading chunk
        chunkLength = oldPNG[chunkPos:chunkPos+4]
        chunkLength = unpack(">L", chunkLength)[0]
        chunkType = oldPNG[chunkPos+4 : chunkPos+8]
        chunkData = oldPNG[chunkPos+8:chunkPos+8+chunkLength]
        chunkCRC = oldPNG[chunkPos+chunkLength+8:chunkPos+chunkLength+12]
        chunkCRC = unpack(">L", chunkCRC)[0]
        chunkPos += chunkLength + 12

        # Parsing the header chunk
        if chunkType == "IHDR":
            width = unpack(">L", chunkData[0:4])[0]
            height = unpack(">L", chunkData[4:8])[0]

        # Parsing the image chunk
        if chunkType == "IDAT":
            try:
                # Uncompressing the image chunk
                bufSize = width * height * 4 + height
                chunkData = decompress( chunkData, -8, bufSize)
                
            except Exception, e:
                # The PNG image is normalized
                print "PNG image is normalized"
                return None

            # Swapping red & blue bytes for each pixel
            newdata = ""
            for y in xrange(height):
                i = len(newdata)
                newdata += chunkData[i]
                for x in xrange(width):
                    i = len(newdata)
                    newdata += chunkData[i+2]
                    newdata += chunkData[i+1]
                    newdata += chunkData[i+0]
                    newdata += chunkData[i+3]

            # Compressing the image chunk
            chunkData = newdata
            chunkData = compress( chunkData )
            chunkLength = len( chunkData )
            chunkCRC = crc32(chunkType)
            chunkCRC = crc32(chunkData, chunkCRC)
            chunkCRC = (chunkCRC + 0x100000000) % 0x100000000

        # Removing CgBI chunk        
        if chunkType != "CgBI":
            newPNG += pack(">L", chunkLength)
            newPNG += chunkType
            if chunkLength > 0:
                newPNG += chunkData
            newPNG += pack(">L", chunkCRC)

        # Stopping the PNG file parsing
        if chunkType == "IEND":
            break
    if newPNG != None:
        file = open(newfileName, "wb")
        file.write(newPNG)
        file.close()
        print "[Python :]Convert ipa icon done"

