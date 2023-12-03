--- 
title: "Decompressing a gzip file by hand (sorta), part 2: Now with Huffman!"
date: 2023-11-26T00:03:59-07:00
draft: true
---

Let's decompress a gzip file by hand, just [like we did last time in part 1](/blog/gzip_investigations), but this time let's decode the decompressed huffman codes too.

Start by writing some data to disk:
```
$ echo "hector the frantic father on an anchor or a rare fat cat sat on the ranch" > test-huff.txt
$ xxd test-huff.txt
00000000: 6865 6374 6f72 2074 6865 2066 7261 6e74  hector the frant
00000010: 6963 2066 6174 6865 7220 6f6e 2061 6e20  ic father on an
00000020: 616e 6368 6f72 206f 7220 6120 7261 7265  anchor or a rare
00000030: 2066 6174 2063 6174 2073 6174 206f 6e20   fat cat sat on
00000040: 7468 6520 7261 6e63 680a                 the ranch.

```
Our file is 74 bytes this time, and specifically chosen to use only 13 characters:

*a, c, e, f, h, i, n, o, r, s, t*; space (0x20) and Line Feed (0x0a).

This string has a lot of repetitions, so hopefully gzip will pick it up.
Since I'm on Windows, I used [7zip-zstd](https://github.com/mcmilk/7-Zip-zstd) to compress the gzip file

```
$ 7z a -mx9 test-huff.txt.gz .\test-huff.txt
$ xxd test-huff.txt.gz
00000000: 1f8b 0808 d76f 6565 0200 7465 7374 2d68  .....oee..test-h
00000010: 7566 662e 7478 7400 158b 410a 0031 0c02  uff.txt...A..1..
00000020: effb 0abf 2621 257b 69c1 e6ff d480 1e64  ....&!%{i......d
00000030: c6ca e823 7425 96b8 fb0f 2c7a 0967 8393  ...#t%....,z.g..
00000040: 2873 8710 9543 11ee 75ad cc51 237d 0fc7  (s...C..u..Q#}..
00000050: 9797 d64a 0000 00                        ...J...
```

## gzip specific info

The first few bytes are quite straightforward:

1. `1f8b` - "magic", hardcoded gzip header
1. `08` - Signifies DEFLATE compression method
1. `08(00001000)` - bit 3 is set, so there will be a filename
1. `d76f 6565` - timestamp 1701146583, UTC Tue Nov 28 04:43:03 2023
1. `02` - compressor used slowest compression
1. `00` - Windows operating system (useful for LF/CLRF). Yes, I am writing this on Windows, since I stopped using WSL recently due to my laptop having *only* 8GB of RAM, which apparently is not enough for Windows these days. I'm shopping for a Mac this black friday.

The next few bytes are the filename:
```
74 65 73 74 2d 68 75 66 66 2e 74 78 74 00
t  e  s  t  -  h  u  f  f  .  t  x  t  NUL
```

# The deflated data

This time, we'll do something different. The file is much bigger at 72 bytes instead of 9 bytes, and we'll be decoding with dynamic huffman codes, which can get pretty gnarly. So, we'll use the [infgen](https://github.com/madler/infgen) program to guide us. Written by the co-author of gzip himself (Mark Adler), `infgen` can decode the gzip file and tell us what each byte is doing. Thanks to [Rendello on Hacker News](https://news.ycombinator.com/item?id=29337292) for letting me know about this.

*Note: infgen requires system provided zlib, which on Windows can be a pain. I had to install MSYS and use the command gcc ./infgen.c -lz -o ./infgen*

Instead of manually inspecting the bitstream with `xxd` all the time, I'll instead use infgen as a solution manual, to decode the text in reverse. If you want to see me inspecting the bitstream, [I do a detailed explanation for a smaller file in Part 1.](/blog/gzip_investigations)

```
$.\infgen.exe -dd .\test-huff.txt.gz
! infgen 3.2 output
!
gzip
!
last                    ! 1
dynamic                 ! 10
count 259 12 16         ! 1100 01011 00010
[... additional output trimmed. See appendix for the full output]
```

The 3 bits of the gzip bitstream tells us that this is the only block in the bitstream, and that it is compressed using dynamic Huffman codes.

We're not going to be inspecting the bitstream too carefully, but just so we're on the same page, this is the bitstream of the DEFLATE data, without the headers, CRC and Length bytes. 
Remember that the bits are packed LSB to MSB, and any integers are interpreted in little endian format (**except Huffman codes, which are packed MSB to LSB**). `xxd` prints bits from MSB to LSB, so you have to read the bitstream backwards. Check part 1 for the details.
```
$ xxd -s 24 -l 55 -b .\test-huff.txt.gz
00000018: 00010101 10001011 01000001 00001010 00000000 00110001  ..A..1
0000001e: 00001100 00000010 11101111 11111011 00001010 10111111  ......
00000024: 00100110 00100001 00100101 01111011 01101001 11000001  &!%{i.
0000002a: 11100110 11111111 11010100 10000000 00011110 01100100  .....d
00000030: 11000110 11001010 11101000 00100011 01110100 00100101  ...#t%
00000036: 10010110 10111000 11111011 00001111 00101100 01111010  ....,z
0000003c: 00001001 01100111 10000011 10010011 00101000 01110011  .g..(s
00000042: 10000111 00010000 10010101 01000011 00010001 11101110  ...C..
00000048: 01110101 10101101 11001100 01010001 00100011 01111101  u..Q#}
0000004e: 00001111                                               .
```

## Starting with Huffman
Instead of decoding the Huffman table, I think it's more instructive to work backwards. We'll start with the final huffman table, then explain how it's encoded using only lengths. Then, we'll see how the lengths are *themselves* encoded using a Run-length encoding (RLE) scheme, which is itself Huffman coded.


### Huffman table

We intentionally restricted ourselves to 13 characters, let's see how they got encoded. 

*Note that, again, since the Huffman codes are packed MSB to LSB, the output of infgen is actually reversed.*

| Char | Huffman code | Infgen's output |
| ---- | --------- | --------------- |
| `' '` | 000 | 000 |
| a | 001 | 100 |
| r | 010 | 010 |
| c | 1000 | 0001 |
| e | 1001 | 1001 |
| h | 1010 | 0101 |
| t | 1011 | 1101 |
| f | 11010 | 01011 |
| n | 11011 | 11011 |
| o | 11100 | 00111 |
| s | 11101 | 10111|
| '\n' | 111110 | 011111 |
| i | 111111 | 11111 |


The codes (almost) form a beautiful prefix-free huffman code, arranged by the frequency of how often the characters appear in the source. But there are some gaps, because gzip has a neat trick to increase compression - it combines literals and lengths into a single Huffman alphabet.
This lets it save extra space, instead of encoding literals and lengths with two separate Huffman codes. 

*Lengths refers to the match lengths, i.e. look backwards N steps. Don't worry, we'll go through it later*

However, for some reason that I don't understand, *distance* is encoded with a separate alphabet. Why this insanity? ¯\\_(ツ)_/¯ ...

The full len/lit huffman tree is actually as follows:

| Char | Huffman code | Infgen's output |
| ---- | --------- | --------------- |
| `' '` | 000 | 000 |
| a | 001 | 100 |
| r | 010 | 010 |
| **3 (len)** | 011 | 110 |
| c | 1000 | 0001 |
| e | 1001 | 1001 |
| h | 1010 | 0101 |
| t | 1011 | 1101 |
| **4 (len)** | 1100 | 0011 |
| f | 11010 | 01011 |
| n | 11011 | 11011 |
| o | 11100 | 00111 |
| s | 11101 | 10111|
| **END** | 11110 | 01111 |
| '\n' | 111110 | 011111 |
| i | 111111 | 11111 |

### Canonicalizing the huffman code

Notice that since we wrote the Huffman code in ascending order, there's really no need for us to specify exactly what the bits are. If we just knew the length of each character's huffman code, we could reconstitute the Huffman code exactly.

Consider the length 3 characters, *space, a, r, 3*. They are arranged in alphabetical (ascii) order, and they go from 000-011.
The length 4 characters, *c, e, h, t*, are similarly in alphabetical order, and start at 1000 to 1011.

This technique is called [Canonical Huffman coding](https://en.wikipedia.org/wiki/Canonical_Huffman_code), and it's an insanely cool trick to represent Huffman codes. Basically every single huffman encoding, even in other compression formats, works like this. Take some time to read the linked Wikipedia article if this doesn't make sense.

So we can represent our Huffman code like this:
| Char | Huffman code | Code Length |
| ---- | --------- | --------------- |
| `' '` | 000 | 3 |
| a | 001 | 3 |
| r | 010 | 3 |
| **3 (len)** | 011 | 3 |
| c | 1000 | 4 |
| e | 1001 | 4 |
| h | 1010 | 4 |
| t | 1011 | 4 |
| **4 (len)** | 1100 | 4 |
| f | 11010 | 5 |
| n | 11011 | 5 |
| o | 11100 | 5 |
| s | 11101 | 5|
| **END** | 11110 | 5 |
| '\n' | 111110 | 6 |
| i | 111111 | 6 |

And when encoding it, we only need to transmit the code lengths, which will tell us how to get the Huffman code back.
The len/lit alphabet goes from 0 to 285, so we could represent our huffman code as a length 286 array like this:
```
0,0,0,0,0,0,0,0,0,0,6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
3,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
0,3,0,4,0,4,5,0,4,6,0,0,0,0,5,5,0,0,3,5,4,0,0,0,0,0,0,0,0,0,0,0
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
5,3,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
```
But this would be incredibly wasteful. Just look at all those zeroes in the middle, begging to get run-length encoded. And so that's what we'll do.
We'd like some kind of RLE encoding that gives just a number of zeroes, then the codelengths. 1-2 zeroes would be encoded normally. Something like this:
```
zeros 10, codelengths 6,
zeros 21, codelengths 3,
zeros 64, codelengths 3 0 4 0 4 5 0 4 6,
zeros 4, codelengths 5 5 0 0 3 5 4,
zeros 138, codelengths 0 5 3 4
rest zeroes
```

I'm sure you won't be surprised to hear that gzip does this exact encoding to shrink down the codelengths. In this encoding:
- the code 0 through 15 represents the codelength itself. Note that this means the maximum codelength of the len/lit huffman code is 15.
- 17 and 18 are used to represent short and long stretches of zeroes respectively, with a fixed number of extra bits afterwards to indicate the number of zeroes
- 16 is for repetitions of the previous element. It's not used in our example.

Let's take an example of this. We'd represent our code above like this:
```
17 [10] 6
18 [21] 3
18 [64] 3 0 4 0 4 5 0 4 6
17 [4] 5 5 0 0 3 5 4
18 [138] 0 5 3 4 0 0 3 3
17 [3] 3 0 2 2 3
```
*The numbers in brackets are fixed length ints, and are not part of the codelengths*

The last thing to specify is how we should represent the codes 0-18. A naive implementation would be to represent them as fixed 5 bit ints, but notice that in our sample above, some codes occur more frequently than others. Wouldn't it be nice to compress those more frequent codes into a shorter number of bits? Oh wait, that's exactly what a Huffman code is, and we've already written all the machinery to wrangle Huffman codes.

So, gzip represents the codes 0-18 using a second round of Huffman codes. In our example, here's the Huffman table for the codelengths:


| Code | Huffman code | Code Length |
| ---- | --------- | --------------- |
| 0 | 00 | 2 |
| 3 | 01 | 2|
| 4 | 100 | 3|
| 5 | 101 | 3|
| 2 | 1100 | 4|
| 6  | 1101 |4|
| 17 | 1110 | 4 |
| 18 | 1111 | 4 |

These second-round code lengths (code lengths of code lengths) are then encoded as fixed 3 bit integers, and laid out in a fixed 16 element array.
```
2,0,4,2,3,3,4,0
0,0,0,0,0,0,0,0
0,4,4
```

Or they *would* be, if the author of gzip hadn't pulled *another* trick. You see, the higher code lengths like 10-15 are quite likely to be zeroes, and so are the shorter code lengths like 1 and 2. So, gzip "guesses" the expected frequency of codelengths, and arranges the codelengths in the order **16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15**. Then, it encodes the length of the nonzero part of the array, and drops any trailing zeroes.

This order, which is totally mystifying when you read it in the gzip spec, makes total sense once you think about how likely it is that a particular codelength shows up.

So our codelengths would instead be encoded in this order:

```
0,4,4,2,0,0,0,4
0,3,0,3,0,2,0,4
0,0,0
```
The non-zero length of the array is 16 and it's encoded separately in the block header. So we can just drop the last 3 elements and get this bit-level encoding:
```
000 100 100 010 000 000 000 100
000 011 000 011 000 010 000 100
```

Since these are **not** themselves Huffman codes, but rather fixed length 3 bit integers, they are packed LSB to MSB just like every other data entity. This point is a bit confusing but that's how it works I guess.
There are 17 bits before this, which specify lengths. So our 48 bits will be packed like this, with **x** representing the unknown bits belonging to other parts of the gzip code:

```
0100000x 00001010 00000000 00110001 00001100 00000010 xxxxxxx1
```
And here it is!

```
00000018: 00010101 10001011 01000001 00001010 00000000 00110001  ..A..1
                            ^^^^^^^  ^^^^^^^^ ^^^^^^^^ ^^^^^^^^ 
0000001e: 00001100 00000010 11101111 11111011 00001010 10111111  ......
          ^^^^^^^^ ^^^^^^^^        ^
00000024: 00100110 00100001 00100101 01111011 01101001 11000001  &!%{i.
0000002a: 11100110 11111111 11010100 10000000 00011110 01100100  .....d
00000030: 11000110 11001010 11101000 00100011 01110100 00100101  ...#t%
00000036: 10010110 10111000 11111011 00001111 00101100 01111010  ....,z
0000003c: 00001001 01100111 10000011 10010011 00101000 01110011  .g..(s
00000042: 10000111 00010000 10010101 01000011 00010001 11101110  ...C..
00000048: 01110101 10101101 11001100 01010001 00100011 01111101  u..Q#}
0000004e: 00001111                                               .
```

Phew 😅!

# Decompressing the gzip file


The process above is completely reversible, so it is left as an exercise to the reader to reverse it on their own 😉

Let's jump ahead to actually decompressing the Huffman codes, since that's more instructive.

```
00000018: 00010101 10001011 01000001 00001010 00000000 00110001  ..A..1
0000001e: 00001100 00000010 11101111 11111011 00001010 10111111  ......
00000030: 11000110 11001010 11101000 00100011 01110100 00100101  ...#t%
                                              ^^       ^^^^^^^^
   (the marked bits above and the rest below comprise the encoded data)
00000036: 10010110 10111000 11111011 00001111 00101100 01111010  ....,z
0000003c: 00001001 01100111 10000011 10010011 00101000 01110011  .g..(s
00000042: 10000111 00010000 10010101 01000011 00010001 11101110  ...C..
00000048: 01110101 10101101 11001100 01010001 00100011 01111101  u..Q#}
0000004e: 00001111                                               .
```

```
0101 1001 0001 1101 00111 010 000 1101 0101 1001 000
h    e    c    t    o     r   ' '   t    h  e    ' ' 

01011 010 100 11011 1101 111111 0001 000 01011 100
f     r   a   n     t    i      c    ' ' f     a   

01 011 110
MATCH 3 14 (the)
```
*We're using infgen's output, which prints Huffman codes in reverse to make it easier to spot in the bitstream. If you want to match it with the Huffman codes we saw earlier, reverse the bits here.*

Let's zoom in on the first MATCH statement. The **110** (reversed) represents the Length/Lit code of 257. Since literals are only from 0-255, this is a Length code, and it represents a match of length 3. How far back do we have to look? Well, the next code that comes up is the distance code, which is also Huffman coded. We didn't decode it, but here is the distance code table:

| Code  | Dist |  Extra bits |Huffman code | Infgen's output |
| ----  | -----| --------- | --------------- | ---- |
| 9     | 25-32 | 3| 00 | 00 |
| 10     | 33-48| 4| 01 | 10 |
| 2     | 3     | 0| 100 |001 |
| 3     | 4     | 0| 101 | 101 |
| 7     | 13- 16| 2| 110 | 011 |
| 11     | 49-64| 4| 111 | 111 |

The distance codes don't all represent the distance exactly, instead they represent a range of distances and there are extra bits encoded afterwards that specify which distance length it really was.

In the example above of MATCH 3 14, we see that the distance code (infgen) is **011**. This corresponds to code 7, which means that the distance is between 13-16, inclusive. The next 2 bits will tell us which one it is. The next two bits are **01**, which tell us that the exact distance to look back is 14.

To execute the match, we look back 14 letters, which points to **1101**, or *t*. So a match of length 3 means that it encodes *the*, which is what we expect, since the word is fa*the*r.

Continuing on:
```
010 000 00111 11011 000 100
r   ' ' o     n     ' ' a

001 0011
MATCH 4 3 (n an)
```

Here we get into the first interesting match. Notice how the match looks back 3 letters, but has a length of 4? This is gzip's way of representing a repeating element (in this case, *n*) within the match itself. 

To decode this, we need to start repeating part of the *decoded* stream itself. Again, confusing at first glance, but it makes it really concise to represent extremely long repeated strings.

For instance, the string *bananananana* could be represented as `b, a, n, match 9 2`.

Let's finish the rest of the code:
```
0001 0101 111 00 110       001 110
c    h    MATCH 3 32 (or ) MATCH 3 3 (or )

100 000 010 100 010 1001
a   ' ' r   a   r   e

101 00 0011        000 0001 101 110
MATCH 4 30 ( fat)  ' ' c    MATCH 3 4 (at )

10111 101 110 0010    10 110
s     MATCH 3 4 (at ) MATCH 3 35 (on )

1000 111 0011     010 0100 10 0011
MATCH 4 57 (the ) r   MATCH 4 37 (anch)

011111 01111
LF     END
```

## Summary
Wasn't that cool?
Some observations:
1. Notice how by the end, gzip has completely compressed out all the space characters.
1. The compression starts out fairly poor, and gradually gets better. This is true of all LZ77 based encodings.
    1. Despite this fact, as the length of the string approaches infinity, LZ77 becomes an optimal encoding.
1. We achieved 74% compression, ignoring the gzip headers and checksums. Here's a breakdown:

- Uncompressed: 74
- DEFLATE data: 55 (74%)
- Compressed data: 26.25 (35%)
- Block header: 2.125
- RLE table: 6
- LenLit table: 13.125
- Distance: 3.625

### Follow ups

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
time 1701146583		! [UTC Tue Nov 28 04:43:03 2023]
xfl 2
os 0
name 'test-huff.txt
gzip
!
last			! 1
dynamic			! 10
count 259 12 16		! 1100 01011 00010
code 17 4		! 100 000
code 18 4		! 100
code 0 2		! 010
code 6 4		! 100 000 000 000
code 5 3		! 011 000
code 4 3		! 011 000
code 3 2		! 010 000
code 2 4		! 100 000
zeros 10		! 111 0111
lens 6			! 1011
zeros 21		! 0001010 1111
lens 3			! 10
zeros 64		! 0110101 1111
lens 3			! 10
lens 0			! 00
lens 4			! 001
lens 0			! 00
lens 4			! 001
lens 5			! 101
lens 0			! 00
lens 4			! 001
lens 6			! 1011
zeros 4			! 001 0111
lens 5			! 101
lens 5			! 101
lens 0			! 00
lens 0			! 00
lens 3			! 10
lens 5			! 101
lens 4			! 001
zeros 138		! 1111111 1111
lens 0			! 00
lens 5			! 101
lens 3			! 10
lens 4			! 001
lens 0			! 00
lens 0			! 00
lens 3			! 10
lens 3			! 10
zeros 3			! 000 0111
lens 3			! 10
lens 0			! 00
lens 2			! 0011
lens 2			! 0011
lens 3			! 10
! stats table 24:4
! litlen 10 6
! litlen 32 3
! litlen 97 3
! litlen 99 4
! litlen 101 4
! litlen 102 5
! litlen 104 4
! litlen 105 6
! litlen 110 5
! litlen 111 5
! litlen 114 3
! litlen 115 5
! litlen 116 4
! litlen 256 5
! litlen 257 3
! litlen 258 4
! dist 2 3
! dist 3 3
! dist 7 3
! dist 9 2
! dist 10 2
! dist 11 3
literal 'h		! 0101
literal 'e		! 1001
literal 'c		! 0001
literal 't		! 1101
literal 'o		! 00111
literal 'r		! 010
literal ' 		! 000
literal 't		! 1101
literal 'h		! 0101
literal 'e		! 1001
literal ' 		! 000
literal 'f		! 01011
literal 'r		! 010
literal 'a		! 100
literal 'n		! 11011
literal 't		! 1101
literal 'i		! 111111
literal 'c		! 0001
literal ' 		! 000
literal 'f		! 01011
literal 'a		! 100
match 3 14		! 01 011 110
literal 'r		! 010
literal ' 		! 000
literal 'o		! 00111
literal 'n		! 11011
literal ' 		! 000
literal 'a		! 100
match 4 3		! 001 0011
literal 'c		! 0001
literal 'h		! 0101
match 3 32		! 111 00 110
match 3 3		! 001 110
literal 'a		! 100
literal ' 		! 000
literal 'r		! 010
literal 'a		! 100
literal 'r		! 010
literal 'e		! 1001
match 4 30		! 101 00 0011
literal ' 		! 000
literal 'c		! 0001
match 3 4		! 101 110
literal 's		! 10111
match 3 4		! 101 110
match 3 35		! 0010 10 110
match 4 57		! 1000 111 0011
literal 'r		! 010
match 4 37		! 0100 10 0011
literal 10		! 011111
end			! 01111
! stats literals 3.8 bits each (153/40)
! stats matches 45.9% (10 x 3.4)
! stats inout 54:5 (50) 74 0
			! 000
! stats total inout 54:5 (50) 74
! stats total block average 74.0 uncompressed
! stats total block average 50.0 symbols
! stats total literals 3.8 bits each
! stats total matches 45.9% (10 x 3.4)
!
crc
length
```
