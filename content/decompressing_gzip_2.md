--- 
title: "Decompressing a gzip file by hand (sorta), part 2: Now with Huffman!"
date: 2023-11-26:03:59-07:00
draft: true
---

Let's decompress a gzip file by hand, just [like we did last time in part 1](/blog/gzip_investigations), but this time let's decode the decompressed huffman codes too.

Start by writing some data to disk:
```
$ echo "To be, or not to be, that is the question:
Whether 'tis nobler in the mind to suffer
The slings and arrows of outrageous fortune," > test-huff.txt
$ xxd test-huff.txt
00000000: 546f 2062 652c 206f 7220 6e6f 7420 746f  To be, or not to
00000010: 2062 652c 2074 6861 7420 6973 2074 6865   be, that is the
00000020: 2071 7565 7374 696f 6e3a 0a57 6865 7468   question:.Wheth
00000030: 6572 2027 7469 7320 6e6f 626c 6572 2069  er 'tis nobler i
00000040: 6e20 7468 6520 6d69 6e64 2074 6f20 7375  n the mind to su
00000050: 6666 6572 0a54 6865 2073 6c69 6e67 7320  ffer.The slings
00000060: 616e 6420 6172 726f 7773 206f 6620 6f75  and arrows of ou
00000070: 7472 6167 656f 7573 2066 6f72 7475 6e65  trageous fortune
00000080: 2c0d 0a                                  ,..

```
Our file is 130 bytes this time, with the last two bytes being CRLF. Yes, I am writing this on Windows, since I stopped using WSL recently due to my laptop having *only* 8GB of RAM, which apparently is not enough for Windows these days.

This string is specifically chosen to have some repetitions, so hopefully gzip will pick it up.
Since we're on Windows, I used [7zip-zstd](https://github.com/mcmilk/7-Zip-zstd) to compress the gzip file

```
$ 7z a -mx9 test-huff.txt.gz .\test-huff.txt
$ xxd test-huff.txt.gz
00000000: 1f8b 0808 bb3f 6465 0200 7465 7374 2d68  .....?de..test-h
00000010: 7566 662e 7478 7400 258a 3b0e c240 1043  uff.txt.%.;..@.C
00000020: fb95 b883 3b9a 9c80 7344 a2de 88d9 64a5  ....;...sD....d.
00000030: 3016 f311 d767 442a dbef 7925 3659 4083  0....gD*..y%6Y@.
00000040: 3210 d78a a307 a657 0a3e 291e 93fa 68cf  2......W.>)...h.
00000050: 430a 18ee 514a b99d d5a7 fe4f efa9 2f04  C...QJ.....O../.
00000060: e139 8658 5b0b f939 7577 f412 dd8c 5f07  .9.X[..9uw...._.
00000070: 0798 617d 17a6 63d0 2255 965b fb01 88d0  ..a}..c."U.[....
00000080: 82a1 8300 0000                           ......
```

## gzip specific info

The first few bytes are quite straightforward:

1. `1f8b` - "magic", hardcoded gzip header
1. `08` - Signifies DEFLATE compression method
1. `08(00001000)` - bit 3 is set, so there will be a filename
1. `bb3f 6465` - timestamp 1701068731, UTC Monday, November 27, 2023 7:05:31 AM
1. `02` - compressor used slowest compression
1. `00` - Windows operating system (useful for LF/CLRF)

The next few bytes are the filename:
```
74 65 73 74 2d 68 75 66 66 2e 74 78 74 00
t  e  s  t  -  h  u  f  f  .  t  x  t  NUL
```

## The deflated data

This time, we'll do something different. The file is much bigger at 130 bytes instead of 9 bytes, and we'll be decoding with dynamic huffman codes, which can get pretty gnarly. So, we'll use the [infgen](https://github.com/madler/infgen) program to guide us. Written by the co-author of gzip himself (Mark Adler), `infgen` can decode the gzip file and tell us what each byte is doing. Thanks to [Rendello on Hacker News](https://news.ycombinator.com/item?id=29337292) for letting me know about this.

*Note: infgen requires system provided zlib, which on Windows can be a pain. I had to install MSYS and use the command gcc ./infgen.c -lz -o ./infgen*

Instead of manually inspecting the bitstream with `xxd` all the time, I'll instead explain what infgen is printing out, section by section. If you want to see me inspecting the bitstream, [I do a detailed explanation for a smaller file in Part 1.](/blog/gzip_investigations)

```
$.\infgen.exe -dd .\test-huff.txt.gz
! infgen 3.2 output
!
gzip
!
last                    ! 1
dynamic                 ! 10
count 261 11 16         ! 1100 01010 00100
code 16 5               ! 101
code 17 3               ! 011
code 18 4               ! 100
code 0 3                ! 011
code 7 2                ! 010 000
code 6 3                ! 011 000
code 5 4                ! 100 000
code 4 4                ! 100 000
code 3 3                ! 011 000
code 2 5                ! 101 000
[... additional output trimmed. See appendix for the full output]
```

### Diving in

```
```


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

# Full infgen output
```
! infgen 3.2 output
!
time 1701068731		! [UTC Mon Nov 27 07:05:31 2023]
xfl 2
os 0
name 'test-huff.txt
gzip
!
last			! 1
dynamic			! 10
count 261 11 16		! 1100 01010 00100
code 16 5		! 101
code 17 3		! 011
code 18 4		! 100
code 0 3		! 011
code 7 2		! 010 000
code 6 3		! 011 000
code 5 4		! 100 000
code 4 4		! 100 000
code 3 3		! 011 000
code 2 5		! 101 000
zeros 10		! 111 101
lens 5			! 1011
lens 0			! 010
lens 0			! 010
lens 7			! 00
zeros 18		! 0000111 0111
lens 3			! 110
zeros 6			! 011 101
lens 7			! 00
zeros 4			! 001 101
lens 6			! 001
zeros 13		! 0000010 0111
lens 7			! 00
zeros 25		! 0001110 0111
lens 6			! 001
lens 0			! 010
lens 0			! 010
lens 7			! 00
zeros 9			! 110 101
lens 5			! 1011
lens 6			! 001
lens 0			! 010
lens 7			! 00
lens 4			! 0011
lens 5			! 1011
lens 6			! 001
lens 6			! 001
lens 5			! 1011
lens 0			! 010
lens 0			! 010
lens 6			! 001
lens 7			! 00
lens 4			! 0011
lens 3			! 110
lens 0			! 010
lens 7			! 00
lens 4			! 0011
repeat 3		! 00 11111
lens 0			! 010
lens 7			! 00
zeros 136		! 1111101 0111
lens 7			! 00
lens 4			! 0011
lens 0			! 010
lens 7			! 00
lens 6			! 001
zeros 5			! 010 101
lens 3			! 110
lens 3			! 110
lens 3			! 110
lens 2			! 01111
lens 2			! 01111
lens 3			! 110
! stats table 34:2
! litlen 10 5
! litlen 13 7
! litlen 32 3
! litlen 39 7
! litlen 44 6
! litlen 58 7
! litlen 84 6
! litlen 87 7
! litlen 97 5
! litlen 98 6
! litlen 100 7
! litlen 101 4
! litlen 102 5
! litlen 103 6
! litlen 104 6
! litlen 105 5
! litlen 108 6
! litlen 109 7
! litlen 110 4
! litlen 111 3
! litlen 113 7
! litlen 114 4
! litlen 115 4
! litlen 116 4
! litlen 117 4
! litlen 119 7
! litlen 256 7
! litlen 257 4
! litlen 259 7
! litlen 260 6
! dist 5 3
! dist 6 3
! dist 7 3
! dist 8 2
! dist 9 2
! dist 10 3
literal 'T		! 101011
literal 'o		! 100
literal ' 		! 000
literal 'b		! 011011
literal 'e		! 0010
literal ',		! 001011
literal ' 		! 000
literal 'o		! 100
literal 'r		! 0110
literal ' 		! 000
literal 'n		! 1010
literal 'o		! 100
literal 't		! 0001
literal ' 		! 000
literal 't		! 0001
match 6 14		! 01 011 010111
literal 't		! 0001
literal 'h		! 000111
literal 'a		! 11101
literal 't		! 0001
literal ' 		! 000
literal 'i		! 10011
literal 's		! 1110
match 3 8		! 1 001 0101
literal 'e		! 0010
literal ' 		! 000
literal 'q		! 0011111
literal 'u		! 1001
literal 'e		! 0010
literal 's		! 1110
literal 't		! 0001
literal 'i		! 10011
literal 'o		! 100
literal 'n		! 1010
literal ':		! 0001111
literal 10		! 01101
literal 'W		! 1001111
literal 'h		! 000111
literal 'e		! 0010
match 3 17		! 000 00 0101
literal 'r		! 0110
literal ' 		! 000
literal ''		! 1110111
literal 't		! 0001
match 3 27		! 010 10 0101
literal 'n		! 1010
literal 'o		! 100
literal 'b		! 011011
literal 'l		! 100111
match 3 12		! 11 101 0101
literal 'i		! 10011
literal 'n		! 1010
match 5 37		! 0100 111 1111111
literal 'm		! 1101111
literal 'i		! 10011
literal 'n		! 1010
literal 'd		! 0101111
literal ' 		! 000
literal 't		! 0001
literal 'o		! 100
literal ' 		! 000
literal 's		! 1110
literal 'u		! 1001
literal 'f		! 00011
literal 'f		! 00011
literal 'e		! 0010
literal 'r		! 0110
literal 10		! 01101
literal 'T		! 101011
match 3 19		! 010 00 0101
literal 's		! 1110
literal 'l		! 100111
literal 'i		! 10011
literal 'n		! 1010
literal 'g		! 111011
literal 's		! 1110
literal ' 		! 000
literal 'a		! 11101
match 3 25		! 000 10 0101
literal 'a		! 11101
literal 'r		! 0110
literal 'r		! 0110
literal 'o		! 100
literal 'w		! 1011111
literal 's		! 1110
literal ' 		! 000
literal 'o		! 100
literal 'f		! 00011
literal ' 		! 000
literal 'o		! 100
literal 'u		! 1001
literal 't		! 0001
literal 'r		! 0110
literal 'a		! 11101
literal 'g		! 111011
literal 'e		! 0010
literal 'o		! 100
literal 'u		! 1001
literal 's		! 1110
literal ' 		! 000
literal 'f		! 00011
literal 'o		! 100
literal 'r		! 0110
literal 't		! 0001
literal 'u		! 1001
literal 'n		! 1010
literal 'e		! 0010
literal ',		! 001011
literal 13		! 0110111
literal 10		! 01101
end			! 0111111
! stats literals 4.4 bits each (448/102)
! stats matches 22.1% (8 x 3.6)
! stats inout 101:2 (110) 131 0
			! 000000
! stats total inout 101:2 (110) 131
! stats total block average 131.0 uncompressed
! stats total block average 110.0 symbols
! stats total literals 4.4 bits each
! stats total matches 22.1% (8 x 3.6)
!
crc
length
```
