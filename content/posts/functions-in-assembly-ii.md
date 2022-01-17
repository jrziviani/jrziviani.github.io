---
title: "Functions in Assembly - Part II"
tags: ['C', 'assembly']
date: 2017-11-18T09:04:30-08:00
draft: false
author: "Jose R. Ziviani"
showToc: true
TocOpen: false
comments: false
disableHLJS: true
searchHidden: true
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
summary: "What is a function from assembly's point of view and how to write it. Part II."
---
### The Call Stack

The real ABI is big, it has pages and more pages explaining the low-level system, object files, dynamic linking, and so on. The fully implementation is beyond the scope of this little project, of course. Here, I will focus in a small part of it which I think is enough to accomplish what I want. Let's start with the figure below:

[![stack frame diagram](/func_assembly_stack_frame.png)](https://openpowerfoundation.org/?resource_lib=64-bit-elf-v2-abi-specification-power-architecture) This figure is the image of a [call stack](https://en.wikipedia.org/wiki/Call_stack). In a nutshell, the call stack exists to assure that functions can live in accordance with other functions, to assure that none of your local variables or your return address will change just because you called `printf()`, or that you can write your recursive algorithm without worrying whether it will return correctly or not. Concluding, what we **really** need to do is to build the call stack for our function **according** to the ABI.

Thus, according to [this ABI](https://openpowerfoundation.org/?resource_lib=64-bit-elf-v2-abi-specification-power-architecture), I will be able to build the call stack by _allocating_ 160 bytes from the stack, save each of those "things" (we'll see them soon) in the gray area, and it's done. Beautiful! But let's address some questions first.

### PowerPC64 ABI questions

**How can I get the stack pointer?**

ABI states that

> The stack pointer, r1, shall always point to the lowest address doubleword of the most recently allocated stack frame.

PowerPC64 has 32 general purpose registers and, as per ABI, the register named **R1** was chosen to keep the stack address.

**How do I "allocate" memory from the stack?**

The stack is already allocated, the operating system did that for you. In PowerPC64 (and RISC) you use **store** instructions to save data into memory and **load** instructions to load data from memory. By adding/subtracting from `r1`, you set the stack pointer to the right slot.

**What are those "things" in the gray area?**

*   **Back Chain**: is the address of the last stack frame. Each function stores the last stack frame address in its own to make it easy to unwind frames whenever necessary. For instance, imagine how that could be useful if you are writing the exception mechanism of your language.
*   **CR Save**: In PowerPC, CR (Condition Register) is a 32-bit register that reflects the results of some operations and provides mechanism for testing/branching. Before changing any bit in it a copy must be saved in the stack and restored before returning.
*   **Reserved**: This space shouldn't be touched.
*   **LR Save**: LR (Link Register) has the address to which our function should return to. The caller, before calling your function, is responsible to set this register and you are responsible to keep it as is. If you intend to call another function (or a recursive call), then you need to save the LR here and restore it before returning.
*   **TOC Pointer**: TOC pointer is stored in register **R2** as per ABI. It's also your responsibility to make sure it will have same value when your function returns. TOC stands for "Table Of Contents" and it's how PowerPC combines GOT (Global Offset Table, used to hold address for [PIC](https://en.wikipedia.org/wiki/Position-independent_code)) and small data section. More information can be found in the references below.
*   **Parameter Save Area (optional)**: In PowerPC, parameters are usually passed by registers (remember, there're 32 general purpose registers). So I don't know much about this one, I read that C variadic arguments `int printf (const char *format, ... )` uses it. Another big advantage of using registers is that all operations in RISC architectures are done within registers so it's an overhead to \[store to\]/\[load from\] memory if we can keep data in registers.
*   **Local Variable Space (optional)**: Each local variable used by the function can be stored here.
*   To know more about these other areas, please refer to: [64-Bit ELF V2 ABI Specification: Power Architecture](https://openpowerfoundation.org/?resource_lib=64-bit-elf-v2-abi-specification-power-architecture).

**Why are 160 bytes allocated from the stack?**:

32 bytes is the minimum required, then 8 times 8 bytes for the Parameter Save Area (if needed), and 8 times 8 bytes for the Local Variable Space (if needed); 32 + (8 \* 8) + (8 \* 8) = 160 (it's also doubleword aligned). This is certainly not optimized but attends my requirement to have some generic for testing purposes.

### Parameters

As I wrote above, parameters are passed in registers, PowerPC64 ABI assigns 8 registers for it from **R3** to **R13**. Vector and floating point data are passed in their own registers but this project don't cover them.

### Return Values

As per the ABI

> Functions that return values of the following types shall place the result in register r3 as signed or unsigned integers, as appropriate, and sign extended or zero extended to 64 bits where necessary:
> 
> *   char
> *   enum
> *   short
> *   int
> *   long
> *   pointer to any type
> *   \_Bool

### Answer to [Part I](/2017/functions-in-assembly) question

The code `int i = my_function(5); // i == 5` should makes sense now: `main()` puts 5 in **R3** register as argument to `my_function()`, which is the **same register used to return value**. Thus, after `my_function()` returns, `main()` reads the return value from **R3** which is, in this case, still **5**.

### The Code

{{< highlight asm >}}
    .align 2
    .type my_function,@function;
    .globl my_function;
    my_function:
        addis 2, 12, .TOC.-my_function@ha;
        addi 2, 2, .TOC.-my_function@l;
        .localentry my_function, .-my_function
        mflr 0
        std 0, 16(1)
        stdu 1, -160(1)
    
        add 3, 3, 4
    
        addi 1, 1, 160
        ld 0, 16(1)
        mtlr 0
        blr
{{< / highlight >}}

All instructions here exists to build the call stack, except `add 3, 3, 4`. The code before the computation code is named **prologue**. In this case, it initializes the TOC pointer in register **R2** for the following reason:

> All functions have a global entry point (GEP) available to any caller and pointing to the beginning of the prologue. Some functions may have a secondary entry point to optimize the cost of TOC pointer management. In particular, functions within a common module sharing the same TOC base value in r2 may be entered using a secondary entry point (the local entry point or LEP) that may bypass the code that loads a suitable TOC pointer value into the r2 register. When a dynamic or global linker transfers control from a function to another function in the same module, it may choose (but is not required) to use the local entry point when the r2 register is known to hold a valid TOC base value.

Basically, the prologue handles the TOC pointer, saves the Link Register and "allocates" 160 bytes by setting the stack pointer. After the computation code, we have the **epilogue** which restores the prologue before returning. In this case, we reset the stack pointer 160 bytes, load the LR address to **R0** and put that value back into the Link Register and return.

To know more about PowerPC instruction set, checkout [IBM Power ISA™ Version 3.0B](https://openpowerfoundation.org/?resource_lib=power-isa-version-3-0).

### The End

Just to make things easier we can create a macro to add both prologue/epilogue for us:

{{< highlight console >}}
    $ cat util.h
{{< / highlight >}}

{{< highlight asm >}}
    #ifndef _UTIL_H
    #define _UTIL_H
    
    #define FUNCTION(name)              \
        .align 2;                       \
        .type name, @function;          \
        .globl name;                    \
        name:                           \
            addis 2, 12, .TOC.-name@ha; \
            addi 2, 2, .TOC.-name@l;    \
            .localentry name,.-name;    \
            mflr 0;                     \
            std 0, 16(1);               \
            stdu 1, -160(1);
    
    #define ENDFUNCTION                 \
        addi 1, 1, 160;                 \
        ld 0, 16(1);                    \
        mtlr 0;                         \
        blr;
    
    #endif
{{< / highlight >}}

{{< highlight console >}}
    $ cat function.S
{{< / highlight >}}

{{< highlight asm >}}
    #include "util.h"
    .align 2
    .printf_fmt:
        .string "\t=> %d\n"
    
    FUNCTION(print_sum)
        add 4, 4, 3
        addis 3, 2, .printf_fmt@toc@ha
        addi 3, 3, .printf_fmt@toc@l
        bl printf
        nop
    ENDFUNCTION
{{< / highlight >}}

{{< highlight console >}}
    $ cat function.c
{{< / highlight >}}

{{< highlight c >}}
    #include <stdio.h>
    extern void print_sum(int a, int b);
    
    int main(void)
    {
        print_sum(10, 8);
        printf("Works! ;-)\n");
        return 0;
    }
{{< / highlight >}}

{{< highlight console >}}
    $ gcc function.S function.c -o function
    $ ./function
            => 18
    Works! ;-)
{{< / highlight >}}

### References

*   [PowerPC 64-bit ELF V2 ABI](https://openpowerfoundation.org/?resource_lib=64-bit-elf-v2-abi-specification-power-architecture)
*   [IBM Power ISA™ Version 3.0B](https://openpowerfoundation.org/?resource_lib=power-isa-version-3-0)
*   [Application binary interface](https://en.wikipedia.org/wiki/Application_binary_interface)
*   [Call Stack](https://en.wikipedia.org/wiki/Call_stack)
*   [PowerPC Assembly](https://www.ibm.com/developerworks/library/l-ppc/)
*   [Function calls and the PowerPC 64-bit ABI](https://www.ibm.com/developerworks/linux/library/l-powasm4/index.html)
