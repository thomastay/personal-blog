---
title: "Building Wasm Interpreter in Golang X86 Assembly"
date: 2022-12-18T01:22:51-08:00
draft: true
---

## Prerequisites
If you understand why:
```c
int rec(int n) {
    if (n <= 1) {
        return 10;
    }
    return rec(n-1) + 2;
}
```
compiles down to:
```asm
rec(int):
        mov     eax, 10
        cmp     edi, 1
        jle     .L14
        sub     rsp, 8
        sub     edi, 1
        call    rec(int)
        add     eax, 2
        add     rsp, 8
        ret
.L14:
        ret
```
