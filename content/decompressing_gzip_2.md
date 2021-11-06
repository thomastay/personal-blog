--- 
title: "Decompressing a gzip file by hand, part 2"
date: 2021-10-17T00:03:59-07:00
draft: true
---


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
