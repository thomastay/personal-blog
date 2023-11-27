--- 
title: "Decompressing a gzip file (almost) by hand, part 2: Now with Huffman!"
date: 2021-10-17T00:03:59-07:00
draft: true
---

Let's decompress a gzip file by hand, just [like we did last time](./blog/gzip_investigations), but this time let's see the decompressed huffman codes too.

Start by writing some data to disk:
```
$ echo "tobeornottobenot" > test-huff.txt
$ xxd test-huff.txt
00000000: 746f 6265 6f72 6e6f 7474 6f62 656e 6f74  tobeornottobenot
00000010: 0d0a

```
Our file is 14 bytes this time, with two bytes at the end as the CLRF indicator. Yes, I am writing this on Windows, since I stopped using WSL recently due to perf issues.

This string is specifically chosen to have some repetitions, so hopefully gzip will pick it up.
s investigate!

This time, since we're on Windows, I used [7zip-zstd](https://github.com/mcmilk/7-Zip-zstd) to compress the gzip file
```
$ 7z a -mx9 test-huff.txt.gz .\test-huff.txt
$ xxd test-huff.txt.gz
00000000: 1f8b 0808 0428 6465 0200 7465 7374 2d68  .....(de..test-h
00000010: 7566 662e 7478 7400 2bc9 4f4a cd2f cacb  uff.txt.+.OJ./..
00000020: 2f01 3180 142f 1700 032b b881 1200 0000  /.1../...+......
```

## gzip specific info

The first few bytes are quite straightforward:

1. `1f8b` - "magic", hardcoded gzip header
1. `08` - Signifies DEFLATE compression method
1. `08(00001000)` - bit 3 is set, so there will be a filename
1. `0428 6465` - timestamp of UTC 
1. `02` - compressor used slowest compression
1. `00` - Windows operating system (useful for LF/CLRF)

The next few bytes are the filename:
```
74 65 73 74 2d 68 75 66 66 2e 74 78 74 00
t  e  s  t  -  h  u  f  f  .  t  x  t  NUL
```

## The deflated data

### Seeing the end goal first
This time, we'll do something different before we start decoding things by hand. Since we'll be decoding with dynamic huffman codes, which can get pretty gnarly, we'll use the [infgen](https://github.com/madler/infgen) program to guide us. Written by the author of DEFLATE himself, Mark Adler, `infgen` will decode the gzip file and tell us what each byte is doing. Thanks to [Rendello on Hacker News](https://news.ycombinator.com/item?id=29337292) for letting me know about this.

*Note: infgen requires system provided zlib, which on Windows can be a pain. I had to install MSYS and do gcc ./infgen.c -lz ./infgen*

```
$.\infgen.exe -dd .\test-huff.txt.gz
! infgen 3.2 output
!
gzip
!
last                    ! 1
fixed                   ! 01
literal 't              ! 00100101
literal 'o              ! 11111001
literal 'b              ! 01001001
literal 'e              ! 10101001
literal 'o              ! 11111001
literal 'r              ! 01000101
literal 'n              ! 01111001
literal 'o              ! 11111001
literal 't              ! 00100101
match 4 9               ! 00 01100 0100000
match 3 7               ! 0 10100 1000000
literal 13              ! 10111100
literal 10              ! 01011100
end                     ! 0000000
                        ! 000
!
crc
length
```

### Diving in


# OLD OLD OLD OLD OLD

Let's look at the first 12 bytes:
```
1 01 11010 01110 0011

00011000111000001000011000011000011000010100010111011110011100101000011111000000

16 HCLEN:

000 110 001 110 000 010 000 110
 16  17  18  0   8   7   9   6

000 110 000 110 000 101 000 101
 10  5   11  4   12  3   13  2


```
## Block header
1 - Final block

10 - Dynamic huffman codes (yay)


HLIT: 01011 = 11 + 257 = 269

HDIST: 01110 = 14 + 1 = 15

HCLEN: 1100 = 12 + 4 = 16

## Decoding the huffman table's huffman table

So there are going to be 16 Code lengths coming up. These will be in 5 bit increments and are to be read in little endian order.

- 16: 0
- 17: 3
- 18: 4
- 0: 3
- 7: 2
- 9: 0
- 6: 3
- 10: 0
- 5: 3
- 11: 0
- 4: 3
- 12: 0
- 3: 5
- 13: 0
- 2: 5

This makes the huffman table:
- 7: 00
- 0: 010
- 4: 011
- 5: 100
- 6: 101
- 17: 110
- 18: 1110
- 2: 11110
- 3: 11111

## Decoding the actual huffman table


```
110      111  100 1110     0101000   011 1110     000000    ...
17       7    5   18         10      4   18         0       ...
rpt 0   10x      repeat 0  21 times      repeat 0 11 times  ...
```

Next, up we have exactly 269 literal code lenths for the literal/length alphabet, which come huffman decoded.

Above we see the manual decoding of the code lengths. But it quickly gets tiresome, so let's write some code to automate this.

```clojure
(defn pad-right [v len pad-val] (vec (concat v (repeat (- len (count v)) pad-val))))
; user=> (pad-right lenlens (count order) 0)
; [0 3 4 3 2 0 3 0 3 0 3 0 5 0 5 0 0 0 0]

(def lenlen [0 3 4 3 2 0 3 0 3 0 3 0 5 0 5])
(def order [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15])
(def lenlens (sort-by first (map vector order (pad-right lenlen (count order) 0))))
; ([0 3] [1 0] [2 0] [3 0] [4 0] [5 0] [6 0] [7 0] [8 2] [9 3] [10 3] [11 3] [12 5] [13 5] [14 0] [15 0] [16 0] [17 3] [18 4])

;; Sort the items in order of the code lengths, then assign an incrementing number to each of them.

```


### Footer

If you see any mistakes, [please correct them on Github](https://github.com/thomastay/personal-blog/issues), or email me at `thomastayac`. Google mail.


# References
I found these articles extremely helpful, in no particular order:
1. [The official deflate spec](https://datatracker.ietf.org/doc/html/rfc1951)
1. [The official gzip spec](https://datatracker.ietf.org/doc/html/rfc1952)
1. [Dissecting the GZIP format, by Joshua Davies](https://commandlinefanatic.com/cgi-bin/showarticle.cgi?article=art001)
1. [Understanding zlib, by Euccas Chen](https://www.euccas.me/zlib/)
1. [An explanation of the Deflate algorithm, by Antaeus Feldspar](https://zlib.net/feldspar.html)
1. [gzip + poetry = awesome, by Julia Evans](https://jvns.ca/blog/2013/10/24/day-16-gzip-plus-poetry-equals-awesome/)
1. [How does gzip work?, by Julia Evans](https://jvns.ca/blog/2013/10/16/day-11-how-does-gzip-work/)
