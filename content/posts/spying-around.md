---
title: "Spying Around"
tags: ['C++', 'hacking', 'linux']
date: 2018-08-12T17:19:27-08:00
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
summary: "Inspecting other process memory for fun..."
---
This small project examines the memory of another process and it prints a map with all mines exposed. The source code is at [Github Gist](https://gist.github.com/jrziviani/b28bd7e15d8ef6fd28f63c44665f32c6).

![mines example](/mines_example.png) When you click on a cell the game checks whether you're safe or not. So, the mouse click triggers an event that calls a function to make that check. Using the command `strings` we can find the function names available.

{{< highlight console >}}
    % strings /usr/bin/gnome-mines
    ...
    minefield_clear_mine
    minefield_multi_release
    minefield_is_location
    minefield_is_cleared
    minefield_has_mine    <=====
    minefield_is_clock_started
    return_value != NULL
    completedField
    ...
{{< / highlight >}}

The amount of printed strings is scary. Yet, after a quick look, we find very promising names such as `minefiled_has_mine`. If that's a function it needs to know where the mines are and our job is to know how to locate them and read them.

{{< highlight console >}}
    % gnome-mines&
    [1] 28978
{{< / highlight >}}

{{< highlight asm >}}
    % gdb -p 28978
    (gdb) disassemble minefield_has_mine 
    Dump of assembler code for function minefield_has_mine:
       0x000056551241db30 <+0>:	endbr64 
       0x000056551241db34 <+4>:	test   %rdi,%rdi
       0x000056551241db37 <+7>:	je     0x56551241db50 <minefield_has_mine+32>
       0x000056551241db39 <+9>:	imul   0x3c(%rdi),%esi
       0x000056551241db3d <+13>:	mov    0x30(%rdi),%rax
       0x000056551241db41 <+17>:	add    %esi,%edx
       0x000056551241db43 <+19>:	mov    (%rax,%rdx,8),%rax
       0x000056551241db47 <+23>:	mov    0x20(%rax),%eax
       0x000056551241db4a <+26>:	retq
       0x000056551241db4b <+27>:	nopl   0x0(%rax,%rax,1)
       0x000056551241db50 <+32>:	sub    $0x8,%rsp
       0x000056551241db54 <+36>:	lea    0x6829(%rip),%rdx        # 0x565512424384
       0x000056551241db5b <+43>:	lea    0x7cde(%rip),%rsi        # 0x565512425840
       0x000056551241db62 <+50>:	xor    %edi,%edi
       0x000056551241db64 <+52>:	callq  0x565512417390 <g_return_if_fail_warning@plt>
       0x000056551241db69 <+57>:	xor    %eax,%eax
       0x000056551241db6b <+59>:	add    $0x8,%rsp
       0x000056551241db6f <+63>:	retq
    End of assembler dump.
    
    (gdb) b *0x000056551241db39
    Breakpoint 1 at 0x56551241db39
    (gdb) c
    Continuing
{{< / highlight >}}

Great `minefield_has_mine` is a function indeed! By clicking on a cell the game should call that function and GDB will luckily stop at the required point.

{{< highlight asm >}}
    Thread 1 "gnome-mines" hit Breakpoint 1, 0x000056551241db39 in minefield_has_mine ()
    (gdb) display/i $pc
    1: x/i $pc
    => 0x56551241db39 <minefield_has_mine+9>:	imul   0x3c(%rdi),%esi
    (gdb) x /gx $rdi + 0x3c
    0x56551330cccc:	0x0000000000000008
    (gdb) print /x $esi
    $1 = 0x0
{{< / highlight >}}

Hmmm, it's multiplying `$rdi+0x3c = 8` with `$esi = 0`. At first sight, it seems that `$rdi+0x3c` is the number of lines in the board and `$esi` is the selected column cell. After the multiplication `$esi` will store the skipped cells to reach to the required cell.

Let's take a deeper look at `$rdi`, it seems to have more information for us.

{{< highlight asm >}}
    (gdb) x /30gx $rdi
    0x56551330cc90:	0x000056551316a5a0	0x0000000000000004
    0x56551330cca0:	0x00005655133c7be0	0x000056551330cc70
    0x56551330ccb0:	0x0000000800000008	0x000000000000000a
    0x56551330ccc0:	0x00005655131327c0	0x0000000800000008
    0x56551330ccd0:	0x0000000100000000	0x0000000000000000
    0x56551330cce0:	0x00007f19aac74450	0x0000001c00000004
    0x56551330ccf0:	0x0000000000000000	0x0000000000000000
    0x56551330cd00:	0x000056551332ee40	0x0000565512fa49e0
    0x56551330cd10:	0x0000000000000000	0xffffffffffffffff
    0x56551330cd20:	0x00000000ffffffff	0x0000000000000000
    0x56551330cd30:	0x0000565512e76170	0x0000000000000001
    0x56551330cd40:	0x0000000000000000	0x000056551330cce0
    0x56551330cd50:	0x0000565512d46020	0x0000000000001202
    0x56551330cd60:	0x0000565512d90a40	0x000056551330cb30
    0x56551330cd70:	0x000056551332ecc0	0x0000000000000000
{{< / highlight >}}

Well, the register seems to have the address of the main game object. At `0x56551330ccb0` we can find the board size (8x8) and the total number of mines (0xa => 10).

{{< highlight asm >}}
    (gdb) ni
    0x000056551241db3d in minefield_has_mine ()
    1: x/i $pc
    => 0x56551241db3d <minefield_has_mine+13>:	mov    0x30(%rdi),%rax
    (gdb) x /gx $rdi+0x30
    0x56551330ccc0:	0x00005655131327c0
    COMMENT: $rdi+0x30 is an address (possibly pointing to another object).
    
    (gdb) ni
    0x000056551241db41 in minefield_has_mine ()
    1: x/i $pc
    => 0x56551241db41 <minefield_has_mine+17>:	add    %esi,%edx
    (gdb) print /x $edx
    $2 = 0x0
    (gdb) print /x $esi
    $3 = 0x0
    COMMENT: $edx has the selected cell line number, it sums to the $esi found above to have the offset to required cell.
    
    (gdb) ni
    0x000056551241db43 in minefield_has_mine ()
    1: x/i $pc
    => 0x56551241db43 <minefield_has_mine+19>:	mov    (%rax,%rdx,8),%rax
    COMMENT: copy the content of [$rdx * 8 + $rax] to $rax. That 8 has nothing to do with the map, it´s possible the number of bytes between different objects of that map.
    
    (gdb) ni
    0x000056551241db47 in minefield_has_mine ()
    1: x/i $pc
    => 0x56551241db47 <minefield_has_mine+23>:	mov    0x20(%rax),%eax
    COMMENT: $rax+0x20 is our cell: 0 if empty, otherwise 1. Copying it to $eax and retuning (next instruction) will return this value.
    
    (gdb) ni
    0x000056551241db4a in minefield_has_mine ()
    1: x/i $pc
    => 0x56551241db4a <minefield_has_mine+26>:	retq
{{< / highlight >}}

![mines explained](/mines_explained.png) Now the job is to translate that assembly code to C language, which is quite straightforward. My code uses the initial heap address and loops the whole range looking for the \[row, column, mine\]. Then, we need to use the same offsets to access the map.

{{< highlight cpp >}}
    base frame = {stoi(argv[2]), stoi(argv[3]), stoi(argv[4])};
    auto address = search_memory(fd, addresses, frame);
    if (address == 0) {
        cerr << "cannot find the board in memory.\n";
        return 4;
    }
    
    pread(fd, &location, sizeof(uint64_t), static_cast<off_t>(address + 0x30));
    pread(fd, &mine_pos, sizeof(int32_t), static_cast<off_t>(address + 0x3c));
    
    for (int i = 0; i < frame.height; ++i) {
        for (int j = 0; j < frame.width; ++j) {
            auto index = 8 * (mine_pos * j + i);
            pread(fd, &has_mine_p, sizeof(uint64_t),
                    static_cast<off_t>((location + index)));
            pread(fd, &has_mine, sizeof(int32_t),
                    static_cast<off_t>(has_mine_p + 0x20));
            cout << has_mine << " ";
        }
        cout << endl;
    }
{{< / highlight >}}

### How to use it

{{< highlight console >}}
    % g++ -std=c++17 -g3 mines.cpp -o mines
    % gnome-mines&
    [1] 13264
    
    % ./mines 13264 16 16 40
    0 0 0 0 0 0 1 0 0 0 0 0 0 1 0 0
    0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0
    1 1 0 0 0 0 0 0 1 0 1 0 0 1 0 1
    1 0 0 0 0 0 0 1 0 1 0 0 0 1 0 0
    1 0 0 1 0 1 0 0 0 1 0 1 0 0 0 1
    0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 1
    0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0
    0 0 0 0 1 0 1 1 0 0 0 0 0 0 0 0
    0 0 1 0 0 0 0 1 0 0 0 0 0 0 0 0
    0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0
    0 0 0 1 0 1 0 0 0 0 1 0 1 0 0 0
    0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0
    0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0
    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
    0 0 0 0 0 0 0 0 0 0 1 0 0 1 0 0
    0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0
{{< / highlight >}}

![mines final](/mines_final.png)
