---
title: "Linux Crash Tool Part I"
tags: ['linux', 'hacking', 'tooling']
date: 2018-09-04T17:20:00-08:00
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
summary: "Using the Linux crash tool to debug process from the kernel perspective."
---
[Crash tool](https://people.redhat.com/anderson/crash_whitepaper/) is basically a sorcery that uses [GDB](https://www.gnu.org/software/gdb/) and black magic to create an impressive Linux debugging tool. At first sight I though it's used to debug crash dump files but it's even better: you can inspect your system memory live!

I've some recent experiences with Crash and I need to write it down here before I forget everything...again 🤣.

### Introducing Crash

After installing the tool and your kernel debug symbols package (Fedora hint: `sudo debuginfo-install kernel`), run:

{{< highlight console >}}
    sudo crash /usr/lib/debug/usr/lib/modules/$(uname -r)/vmlinux
    crash 7.2.3++
    [snip...]
          KERNEL: vmlinux
        DUMPFILE: /proc/kcore
            CPUS: 128
            DATE: Wed Sep  5 07:53:06 2018
          UPTIME: 00:04:42
    LOAD AVERAGE: 0.84, 0.44, 0.17
           TASKS: 1294
        NODENAME: boston118
         RELEASE: 4.19.0-rc1zvn+
         VERSION: #4 SMP Thu Aug 30 15:55:20 CDT 2018
         MACHINE: ppc64le  (2250 Mhz)
          MEMORY: 512 GB
             PID: 6311
         COMMAND: "crash"
            TASK: c000003fe0631380  [THREAD_INFO: c000003e28760000]
             CPU: 16
           STATE: TASK_RUNNING (ACTIVE)
    
    crash>
{{< / highlight >}}

### Basic Usage

These are the basic commands. The [documentation](https://people.redhat.com/anderson/crash_whitepaper/#COMMAND_SET) lists them all.

{{< highlight console >}}
    # lists commands.
    crash> help
    # gets help for a particular command.
    crash> help <command>
    # lists all process running.
    crash> ps
    # filters the list with grep.
    crash> ps | grep <pattern>
    # sets the context to a particular process.
    crash> set <pid>
    # backtrace of the current context (set ^).
    crash> bt
    # backtrace of that pid.
    crash> bt <pid>
    # shows kernel messages.
    crash> log
    # prints the content of address in a structured format, any kernel struct may be used.
    # Garbage will be printed if data doesn't match the struct.
    crash> struct <struct name> <address>
    # prints the struct, function, symbol definition.
    crash> whatis <name>
    
    # GDB commands
    # prints the content of a memory location.
    crash> x /fmt <address>
    # disassembles a function by its address in .text or symbol name.
    crash> dis <address> | <function name>
    # prints the source file around the line specified.
    crash> l <function name>:<line number>
{{< / highlight >}}

Kernel modules symbols aren't loaded automatically and it's important to know how to add them (actually it's a GDB command). See how I load KVM symbols.

{{< highlight console >}}
    crash> l kvm_init
    Function "kvm_init" not defined.
    gdb: gdb request failed: l kvm_init
    
    # another terminal
    $ cd /sys/module/kvm/sections/
    $ sudo cat .text
    0xc008000010b80000
    $ sudo cat .data
    0xc008000010bab5f8
    $ sudo cat .bss
    0xc008000010bae680
    
    # back to crash terminal
    crash> add-symbol-file /home/ziviani/linux/arch/powerpc/kvm/kvm.o 0xc008000010b80000
    -s .data 0xc008000010bab5f8 -s .bss 0xc008000010bae680
    add symbol table from file "/home/ziviani/linux/arch/powerpc/kvm/kvm.o" at
            .text_addr = 0xc008000010b80000
            .data_addr = 0xc008000010bab5f8
            .bss_addr = 0xc008000010bae680
    Reading symbols from /home/ziviani/linux/arch/powerpc/kvm/kvm.o...done.
    
    crash> l kvm_init
    3987            kvm_arch_vcpu_put(vcpu);
    3988    }
    3989    
    3990    int kvm_init(void *opaque, unsigned vcpu_size, unsigned vcpu_align,
    3991                      struct module *module)
    3992    {
    3993            int r;
    3994            int cpu;
    3995    
    3996            r = kvm_arch_init(opaque);
    
    # we can use the function address instead
    crash> l *0xc008000010b80000+0x5e30
    3987            kvm_arch_vcpu_put(vcpu);
    3988    }
    ...
{{< / highlight >}}

**Notes:**

*   `0xc008000010b80000` is the address chose by Linux to load KVM.
*   `0x5e30` is the offset to reach `kvm_init` function:

{{< highlight console >}}
    $ objdump -t kvm.o | grep kvm_init
    0000000000005e30 g F .text 0000000000000330 0x60 kvm_init
{{< / highlight >}}

In my next post I intend to do something more practical with that for IBM PowerPC, stay tuned.
