--- 
title: "Decompressing a gzip file by hand"
date: 2021-10-16T00:03:59-07:00
draft: false
---

Let's make a gzipped file and see what's in it. We'll keep it simple: just write 8 'a's to a file. 

```
$ echo "aaaaaaaa" > test.out
$ xxd test.out
00000000: 6161 6161 6161 6161 0a     aaaaaaaa.
```

As we can see, our file is 9 bytes long. We have 8 'a' bytes written, plus a Line Feed (LF) character written at the end.

Let's make the gzip file now. We'll do `gzip -1`, since that will use the fastest compression mode and give us more things to talk about.

```
$ gzip -1 test.out
$ xxd test.out.gz
00000000: 1f8b 0808 bf35 6a61 0403 7465 7374 2e6f  .....5ja..test.o
00000010: 7574 004b 4c84 002e 00b6 66d7 ad09 0000  ut.KL.....f.....
00000020: 00
```

_Disclaimer: I made this post as a learning exercise, and any mistakes I make here are my own. I enjoy low level programming but do web dev at Teams as my day job._

## gzip specific info

The first few bytes are quite straightforward:

1. `1f8b` - "magic", hardcoded gzip header
1. `08` - Signifies DEFLATE compression method
1. `08(00001000)` - bit 3 is set, so there will be a filename
1. `bf35 6a61` - timestamp of UTC Saturday, October 16, 2021 2:15:27 AM
1. `04` - compressor used fastest algo (that's what the -1 was for)
1. `03` - Unix operating system (useful for LF/CLRF)

The next few bytes are the filename:
```
74 65 73 74 2e 6f 75 74 00
t  e  s  t  .  o  u  t  NUL
```

## The deflated data

The data starts from byte 0x13, with 4b. To decode, we'll need to see the individual bits since DEFLATE packs the information in bits that can cross the byte boundary. It's not uncommon to have codes that are 5 bits or 9 bits.


```
$ xxd -s 19 -b test.out.gz
00000013: 01001011 01001100 10000100 00000000 00101110 00000000  KL....
00000019: 10110110 01100110 11010111 10101101 00001001 00000000  .f....
0000001f: 00000000 00000000
```

Let's break it down. Unfortunately, xxd prints out the bytes one by one, from MSB to LSB. But in gzip, the bytes are packed LSB to MSB. So we have to reverse the strings byte by byte. Let's also define some convenience functions to help us compute numbers

```clojure
(require [clojure.string :as str])

(defn reverse-str-bytewise [s] 
  (->> (str/replace s " " "") 
       (partition 8) 
       (map #(apply str %)) 
       (map str/reverse)))

(comment (reverse-str-bytewise "01001011 01001100 10000100 00000000 00101110 00000000"))
; ("11010010" "00110010" "00100001" "00000000" "01110100" "00000000")
; ^^^^^^ This is the bitstream we will examine below ^^^^^^

(defn str->bits [s] (->> s (str/reverse) (mapv #(if (= % \1) 1 0))))

(comment (str->bits "110010"))
; [0 1 0 0 1 1]

(defn bin->dec [s] 
  (->> s 
       (str->bits) 
       (reduce-kv (fn [acc, i, elem] 
                    (if (= elem 1) (+ acc (bit-shift-left 1 i)) acc)) 
                  0))

(comment (bin->dec "10001"))
; 17
```

## Decoding the block
```
8bitswise: 11010010   00110010 00100001 00000000 01110100 00000000
separated: 1 10 10010001 10010001 0000100 00000 00111010 0000000 00
```

1 - final block

01 - compressed with fixed huffman codes (don't forget that although the bitstream says "10", it is read as 01 because the data literals are to be interpreted in little endian format)

Next we have to decode the huffman codes. If you haven't read [the official DEFLATE spec](https://datatracker.ietf.org/doc/html/rfc1951#page-12), read section 3.2.6 (fixed huffman codes) before continuing on or it won't make much sense. I've included the huffman table below:
```
Lit Value    Bits        Codes
---------    ----        -----
  0 - 143     8          00110000 through
                         10111111
144 - 255     9          110010000 through
                         111111111
256 - 279     7          0000000 through
                         0010111
280 - 287     8          11000000 through
                         11000111
```

To decode the huffman codes, we have to read up to the next 9 bits
Then, the prefix of the next 9 bits will tell us how many bits we really needed to read.
You can conceptually think of this as walking down the edges of the huffman tree too, but huffman decoders will usually just read 9 bits, look them up in the table, and then "put back" whatever bits it didn't need.

100100011 - this has the prefix 100, which tells us that is a literal between 0-143. So it is only 8 bits (1001 0001).

_Don't forget that the huffman codes are packed LSB to MSB, but are to be interpreted as an integer in big endian format. Why this insanity?_ ¯\\_(ツ)_/¯ ... _NOT my decision._



Decoding, we get: val = (10010001 subtract 00110000) = 145 - 48 = 97


97 is the ASCII for 'a'. Perfect!

Decoding the rest of the bits, we get:
```
1 10 10010001 10010001 0000100  00000       00111010    0000000    00
     97       97         260     0            58          256      -
     'a'      'a'    repeat 6x  1 behind    0x10 (LF)    HALT     <padding>
     LIT      LIT       LEN     DIST        LIT         
```

Those are our 8 'a's! two literals followed by a repeat of 6 'a's, then a LF. 

The "repeat 6x, 1 behind" is a length+distance (LEN,DIST) code, and it tells the decoder that the character to be repeated is the previous one that it just decoded. Which is 'a', in this case.

Not too shabby, we've encoded our 8 'a's and LF (originally 72 bits) into 46 bits with 2 padding bits.

## Finishing off - checksum and size

Let's finish off the gzip file. Next we're supposed to see a CRC32. Going to an online crc32 tool, we see that the uncompressed 8 'a's with a line feed will generate: `ad d7 77 b6`.
Indeed, if we look at the hex stream again:

```
$ xxd test.out.gz
00000000: 1f8b 0808 bf35 6a61 0403 7465 7374 2e6f  .....5ja..test.o
00000010: 7574 004b 4c84 002e 00b6 66d7 ad09 0000  ut.KL.....f.....
00000020: 00                
```

We can clearly see `b6 66 d7 ad`, in little endian byte order. This is the crc checksum.

The next 4 bytes `09 00 00 00` is little endian byte order for 9 bytes. Indeed, we decoded 9 bytes, and there are 9 bytes in our input file.

## Summary
So this is the file breakdown:

```
gzip info: 1f8b 0808 bf35 6a61 0403 
filename: 7465 7374 2e6f 7574 00 
DEFLATE data: 4b 4c 84 00 2e 00
crc32: b6 66 d7 ad 
size: 09 00 00 00                
```


If you see any mistakes, [please correct them on Github](https://github.com/thomastay/personal-blog/issues), or email me at `thomastayac`. Google mail.


# References
I found these articles extremely helpful, in no particular order:
1. [The official deflate spec](https://datatracker.ietf.org/doc/html/rfc1951)
1. [The official gzip spec](https://datatracker.ietf.org/doc/html/rfc1952)
1. [Dissecting the GZIP format, by Joshua Davies](https://commandlinefanatic.com/cgi-bin/showarticle.cgi?article=art001)
1. [Understanding zlib, by Euccas Chen](https://www.euccas.me/zlib/)
1. [An explanation of the Deflate algorithm, by Antaeus Feldspar](https://zlib.net/feldspar.html)
