---
title: "Using the KVM API - PowerPC 64 version"
tags: ['C', 'assembly', 'kvm', 'ppc']
date: 2017-09-05T06:19:26-08:00
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
summary: "Interacting with PPC64 KVM module in C."
---
Based on a very nice article from [LWN.net](https://lwn.net) named [Using the KVM API](https://lwn.net/Articles/658511), this is **basically** the same but for PowerPC 64bit.

### Guest code

The code below is intended to run _bare-metal_, neither the operating system nor SLOF to support us, so let's do it simple. Also, the referred article embedded opcode in his C program, but I'm going to run a separate binary in assembly.

{{< highlight console >}}
    $ cat code.s
{{< / highlight >}}

{{< highlight asm >}}
    li 16,8 # stores number 8 in register R16
    li 17,4 # stores number 4 in register R17
    mullw 18,16,17 # stores the result of R16 * R17 in R18
{{< / highlight >}}

Now, the `.ld` directives and the binary code.

{{< highlight console >}}
    $ cat code.ld
    OUTPUT_FORMAT(elf64-powerpc)
    SECTIONS
    {
        . = 0x100;
        .text : { *(.text) }
    }
{{< / highlight >}}

{{< highlight console >}}
    $ as -mbig -mpower8 code.s -o code.o # power8 big-endian
    $ ld -T code.ld code.o -o code.bin
    $ objdump -d code.bin
    code.bin:     file format elf64-powerpc
{{< / highlight >}}

{{< highlight asm >}}
    Disassembly of section .text:
    
    0000000000000100 <.text>:
     100:	3a 00 00 08 	li      r16,8
     104:	3a 20 00 04 	li      r17,4
     108:	7e 50 89 d6 	mullw   r18,r16,r17
{{< / highlight >}}

After a System Reset interrupt, PowerPC resumes execution at address `0x100`, this is the reason why the program is linked at such address.

### Using the KVM API

Details about KVM API is well covered by [Using the KVM API](https://lwn.net/Articles/658511), I'll focus on PowerPC64 only. Let's initializes the registers by zero'ing them, except for:

{{< highlight console >}}
    $ cat vm.c
{{< / highlight >}}

{{< highlight c >}}
    /* [snip] */
    int setup_registers(struct virtual_machine *vm)
    {
        if (ioctl(vm->vcpufd, KVM_GET_SREGS, &vm->sregs) == -1) {
            return 10;
        }
        vm->sregs.pvr = 0x004d0200;
        vm->sregs.u.s.sdr1 = 0x3fff80400004;
    
        if (ioctl(vm->vcpufd, KVM_SET_SREGS, &vm->sregs) == -1) {
            return 11;
        }
    
        struct kvm_regs regs = {
            .pc = 0x100,
            .msr = 0x8000000000000000ULL,
        };
    
        if (ioctl(vm->vcpufd, KVM_SET_REGS, &regs) == -1) {
            return 12;
        }
    
        return 0;
    }
    /* [snip] */
{{< / highlight >}}

The full source code can be found at [my github repo](https://github.com/jrziviani/kvm-lab/blob/master/vm.c).

*   **PVR - Processor Version Register**: the value `0x4d0200` includes the version/revision for the Power8 system used to develop this code.
*   **SDR1 - Storage Description Register 1**: defines the high-order bit for physical base address plus the page table size. The value here is the same that QEMU uses but it won't make any difference now since we're in real mode. _**NOTE**: this register doesn't exist in newer PPC versions, page table locations are now stored in process table entries._
*   **MSR - Machine State Register**: the value has the first bit set to 1. In other words, it indicates that the system is running in 64-bit mode.
*   **PC - Program Counter**: Actually it's not a PowerPC register. In Power, the next instruction address is basically a call to instruction `bcl` (branch condition and link) that will put the effective address following the branch address into the `LR` (Link Register). Here, it's set to address `0x100` because Power will resume the execution at it (recall that we linked our assembly code to the same address).

If you compile and run the code, you'll get the expected result:

{{< highlight console >}}
    $ gcc -O3 vm.c -o vm
    $ ./vm
    KVM version 12
    VM created successfuly
    Registers set successfuly
    R 0: 0	R 1: 0	R 2: 0	R 3: 0	
    R 4: 0	R 5: 0	R 6: 0	R 7: 0	
    R 8: 0	R 9: 0	R10: 0	R11: 0	
    R12: 0	R13: 0	R14: 0	R15: 0	
    R16: 0	R17: 0	R18: 0	R19: 0 <====
    R20: 0	R21: 0	R22: 0	R23: 0	
    R24: 0	R25: 0	R26: 0	R27: 0	
    R28: 0	R29: 0	R30: 0	R31: 0	
    -------------------
    R 0: 0	R 1: 0	R 2: 0	R 3: 0	
    R 4: 0	R 5: 0	R 6: 0	R 7: 0	
    R 8: 0	R 9: 0	R10: 0	R11: 0	
    R12: 0	R13: 0	R14: 0	R15: 0
    R16: 8	R17: 4	R18: 32	R19: 0 <====
    R20: 0	R21: 0	R22: 0	R23: 0	
    R24: 0	R25: 0	R26: 0	R27: 0	
    R28: 0	R29: 0	R30: 0	R31: 0	
    -------------------
    exit reason: 0x0
{{< / highlight >}}

### Little Endian

Power is a bi-endian architecture, it's possible to run the same in little-endian mode and it doesn't require huge modifications, here we go:

{{< highlight console >}}
    $ cat code.ld
    OUTPUT_FORMAT(elf64-powerpcle)
    SECTIONS
    {
        . = 0x100;
        .text : { *(.text) }
    }

    $ as -mlittle -mpower8 code.s -o code.o # power8 little-endian
    $ ld -T code.ld code.o -o code.bin
{{< / highlight >}}

Good, the binary code is in little-endian mode, let's change the `vm.c`:

{{< highlight console >}}
    $ cat vm.c
{{< / highlight >}}

{{< highlight c >}}
    int setup_registers(struct virtual_machine *vm)
    /* [snip] */
        struct kvm_regs regs = {
            .pc = 0x100,
            .msr = 0x8000000000000001ULL,
        };
    /* [snip] */
{{< / highlight >}}

That `1` bit in `MSR` now tells Power to run in little-endian mode. Recompile it again and it's done.

### References

*   [My sample source code](https://github.com/jrziviani/kvm-lab/blob/master/vm.c)
*   [Using the KVM API](https://lwn.net/Articles/658511)
*   [64-Bit ELF V2 ABI Specification: Power Architecture](https://openpowerfoundation.org/?resource_lib=64-bit-elf-v2-abi-specification-power-architecture)
*   [IBM Power ISA™ Version 3.0B](https://openpowerfoundation.org/?resource_lib=power-isa-version-3-0)
*   [Linux on Power Architecture Platform Reference](https://openpowerfoundation.org/?resource_lib=linux-on-power-architecture-platform-reference)
