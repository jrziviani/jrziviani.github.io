---
title: "Touching Around"
tags: ['C++', 'hacking', 'linux']
date: 2018-08-20T17:19:41-08:00
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
summary: "Now, let's change other's process memory values."
---
Just an update regarding my last [post](/2018/spying-around). I was asked to write a code to change other's process memory and it was straightforward as well.

{{< highlight udiff >}}
    --- /home/ziviani/temp/mines.cpp.1
    +++ /home/ziviani/temp/mines.cpp
    @@ -77,7 +77,7 @@
         }
     
         string mem_path("/proc/" + string(argv[1]) + "/mem");
    -    int fd = open(mem_path.c_str(), O_RDONLY);
    +    int fd = open(mem_path.c_str(), O_RDWR);
         if (fd < 0) {
             cerr << "cannot open " << mem_path << ".\n";
             return 3;
    @@ -93,6 +93,7 @@
         pread(fd, &location, sizeof(uint64_t), static_cast<off_t>(address + 0x30));
         pread(fd, &mine_pos, sizeof(int32_t), static_cast<off_t>(address + 0x3c));
     
    +    int32_t test = 1;
         for (int i = 0; i < frame.height; ++i) {
             for (int j = 0; j < frame.width; ++j) {
                 auto index = 8 * (mine_pos * j + i);
    @@ -100,10 +101,12 @@
                         static_cast<off_t>((location + index)));
                 pread(fd, &has_mine, sizeof(int32_t),
                         static_cast<off_t>(has_mine_p + 0x20));
    +            pwrite(fd, &test, sizeof(int32_t), static_cast<off_t>(has_mine_p + 0x20));
                 cout << has_mine << " ";
             }
             cout << endl;
         }
    +
         close(fd);
     
         return 0;
{{< / highlight >}}

If you don't see what I did, I set 1 to the whole map. In other words, mines in every cell. :-)

![mines written](/mines_written.png)
