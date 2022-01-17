---
title: "Class Inheritance in C"
tags: ['C', 'Python']
date: 2014-12-24T06:18:30-08:00
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
summary: "Implementing class inheritance in C language - or how Python implements class inheritance support in C."
---
C language doesn't offer support for object oriented programming, but it's not necessarily an obstacle. Actually, it's been used behind the scenes for a long time. Let's see how Python interpretor implements it own class inheritance in C.

### The Python Way

Python is an object oriented language, it's possible to write a base class and classes deriving (subclasses) from it. However, the interpretor (CPython) is written in C and, as mentioned, C doesn't offer such support. So, let's see how they implement it.

PyObject is the _base class_ in Python, it's the mother of everybody else. But, in C, it's a simple `struct` with some fields `#defined _HEAD_`, which are inhered (actually it's defined) by any of its subclass.

{{< highlight c >}}
    // http://svn.python.org/view/python/trunk/Include/object.h
    ...
    #define _PyObject_HEAD_EXTRA
    #define _PyObject_EXTRA_INIT
    ...
    
    #define PyObject_HEAD                   \
        _PyObject_HEAD_EXTRA                \
        Py_ssize_t ob_refcnt;               \
        struct _typeobject *ob_type;
     
    #define PyObject_VAR_HEAD \
        PyObject_HEAD \
        Py_ssize_t ob_size; /* Number of items in variable part */
     
    typedef struct _object {
        PyObject_HEAD
    } PyObject;
{{< / highlight >}}

See below the children of `PyObject`: `PyStringObject`, `PyFloatObject`, and `PyListObject`. **But how do I know that they're children of PyObject?** It'll be clearer later, but take a look at the structures definitions, they all have `PyObject_HEAD` or `PyObject_VAR_HEAD` (which also starts with `PyObject_HEAD`) field.

{{< highlight c >}}
    // http://svn.python.org/view/python/trunk/Include/stringobject.h
    typedef struct {
        PyObject_VAR_HEAD
        long ob_shash;
        int ob_sstate;
        char ob_sval[1];
    } PyStringObject;
     
    // http://svn.python.org/view/python/trunk/Include/floatobject.h
    typedef struct {
        PyObject_HEAD
        double ob_fval;
    } PyFloatObject;
     
    // http://svn.python.org/view/python/trunk/Include/listobject.h
    typedef struct {
        PyObject_VAR_HEAD
        PyObject **ob_item;
        Py_ssize_t allocated;
    } PyListObject;
{{< / highlight >}}

A simple class diagram could be made from those structures:

![PyObject object diagram](/pyobject_diagram.png)

### Casting

Here the magic begins. In the code below focus on `return ((PyListObject*)op)->ob_item[i]`.

Do you know [type casting](http://en.cppreference.com/w/c/language/cast)? In a nutshell, it's the way to force the conversion between two different data types. In C, casts are usually dangerous and must be used wisely.

{{< highlight c >}}
    // http://svn.python.org/view/python/trunk/Objects/listobject.c?view=markup
    PyObject *PyList_GetItem(PyObject *op, Py_ssize_t i)
    {
        if (!PyList_Check(op)) {
            PyErr_BadInternalCall();
            return NULL;
        }
    
        if (i < 0 || i >= Py_SIZE(op)) {
            if (indexerr == NULL) {
                indexerr = PyString_FromString("list index out of range");
                if (indexerr == NULL)
                    return NULL;
            }
            PyErr_SetObject(PyExc_IndexError, indexerr);
            return NULL;
        }
        return ((PyListObject *)op)->ob_item[i];
    }
{{< / highlight >}}

See, `op` is a data pointer of a `PyObject` type. That `((PyListObject*)op)` casts (forced conversion) `op` to a `PyListObject` type (note the `PyList_Check(op)` as a sanity check). Then it accesses `ob_item` field to return the `i` item. Note that `ob_item` is an array of `PyObject` data pointers as correctly specified in the function signature.

**Those structures (PyObject and PyList) are completely different, why don't that break the program?**

In this particular case, the conversion is safe and well behaved because it's defined by the [C99 standard.](http://flash-gordon.me.uk/ansi.c.txt).

> Within a structure object, the non-bit-field members and the units in which bit-fields reside have addresses that increase in the order in which they are declared. A pointer to a structure object, suitably cast, points to its initial member (or if that member is a bit-field, then to the unit in which it resides), and vice versa. There may therefore be unnamed holes within a structure object, but not at its beginning, as necessary to achieve the appropriate alignment.

Basically, it means that a **pointer to any `struct` always point to its first element** (declaration order), so you can cast it to any other `struct` if (and only if) its first field have the same type. The compiler will handle different `sizeof(struct)` for us.

### Show me some code

Based on a sample C code, let's go through the not-optimized code generated by GCC to see how it's implemented.

{{< highlight c "linenos=inline" >}}
    #include <stdlib.h>
    #include <stdio.h>
    
    #define HEAD int type;
    
    enum { INTEGER, FLOAT };
    
    typedef struct
    {
        HEAD
    } Number;
    
    typedef struct
    {
        HEAD
        int val;
    } Integer;
    
    typedef struct
    {
        HEAD
        float val;
    } Float;
    
    int main()
    {
        Integer i;
        i.type = INTEGER;
        i.val  = 42;
    
        Float f;
        f.type = FLOAT;
        f.val  = 36.85;
    
        Number **numbers = (Number**)malloc(sizeof(Number*) * 2);
    
        numbers[0] = (Number*)&i;
        numbers[1] = (Number*)&f;
    
        // for debugging purpose ↓
        int y = ((Integer*)numbers[0])->val;
    
        int x = numbers[0]->type;
        x = numbers[1]->type;
        // for debugging purpose ↑
    
        for (unsigned int count = 0; count < 2; ++count)
        {
            switch (numbers[count]->type)
            {
                case INTEGER:
                    printf("%d - Integer: %d\n", 
                            count, 
                            ((Integer*)numbers[count])->val);
                    break;
    
                case FLOAT:
                    printf("%d - Float: %.2f\n", 
                            count, 
                            ((Float*)numbers[count])->val);
                    break;
    
                default:
                    break;
            }
        }
    
        free(numbers);
    
        return 0;
    }
{{< / highlight >}}

{{< highlight console >}}
    # Compiling:
    $ gcc -g -std=c99 code.c -o codebin
    
    # Running:
    $ ./codebin
    0 - Integer: 42
    1 - Float: 36.85
{{< / highlight >}}

Now let's see the internals.

{{< highlight asm >}}
    Number **numbers = (Number**)malloc(sizeof(Number*) * 2);
    
    0x4005e3 <main+38>      mov    $0x10,%edi
    0x4005e8 <main+43>      callq  0x4004c0 <malloc@plt>
    0x4005ed <main+48>      mov    %rax,-0x8(%rbp)
    
    (gdb) info registers rax
    rax            0x602010 6299664
    
    (gdb) x/wx $rbp-0x8
    0x7fffffffe3c8: 0x00602010
    
    (gdb) x/wx 0x00602010
    0x602010:       0x00000000
{{< / highlight >}}

The `malloc()` function gets the size stored in `edi` register and writes the memory address in `rax`. That address is copied to `rbp-0x8`, the place of our variable **numbers** in the stack.

![malloc instructions](/c_poly_malloc.png)

{{< highlight asm >}}
    numbers[0] = (Number*)&i;
    
    0x4005f1 <main+52>      mov    -0x8(%rbp),%rax
    0x4005f5 <main+56>      lea    -0x20(%rbp),%rdx
    0x4005f9 <main+60>      mov    %rdx,(%rax)
    (gdb) x/wx $rbp-0x20
    0x7fffffffe3b0: 0x00000000
    
    (gdb) x/2wx 0x00602010
    0x602010:       0xffffe3b0      0x00007fff
{{< / highlight >}}

Register `rbp-0x8` (AKA "numbers") is copied to `rax`, the address of `rbp-0x20` (address of struct "i") is copied into `rdx`, and the content of `rdx` (address of "i") is stored in the heap. The instruction **`mov %rdx,(%rax)`** copies the `rdx` content into the place where `rax` content is pointing to, which is the memory that `malloc()` gave to me. Note that `rbp-0x20` is the place of `Integer` first element.

![assembly instructions](/c_poly_cast1.png)

> **Important**: the address of a local variable (stack) was stored in the heap, fortunately we are running everything in `main()`. But it can be dangerous in other scenarios. Read about [stack frames](https://en.wikipedia.org/wiki/Call_stack#Structure).

{{< highlight asm >}}
    int y = ((Integer*)numbers[0])->val;
    
    0x40060b <main+78>      mov    -0x8(%rbp),%rax
    (gdb) info registers rax
    rax            0x602010 6299664
    
    0x40060f <main+82>      mov    (%rax),%rax
    (gdb) info registers rax
    rax            0x7fffffffe3b0   140737488348080
    
    (gdb) x/wx 0x7fffffffe3b0+4
    0x7fffffffe3b4: 0x0000002a ==> (42 int)
    
    0x400612 <main+85>      mov    0x4(%rax),%eax
    (gdb) info registers eax
    eax            0x2a     42
    
    0x400615 <main+88>      mov    %eax,-0x28(%rbp)
    (gdb) x/wx $rbp-0x28
    0x7fffffffe3a8: 0x0000002a
{{< / highlight >}}

Note that the cast to **Integer** "grants" a **Number** variable access to a field that only **Integer** has defined (`val`).

![assembly instructions](/c_poly_cast2.png)

{{< highlight asm >}}
    int x = numbers[0]->type;
    
    0x400618 <main+91>      mov    -0x8(%rbp),%rax
    0x40061c <main+95>      mov    (%rax),%rax
    0x40061f <main+98>      mov    (%rax),%eax
    (gdb) info registers rax
    rax            0x0      0
    
    0x400621 <main+100>     mov    %eax,-0x24(%rbp)
    (gdb) x/wx $rbp-0x24
    0x7fffffffe3ac: 0x00000000
{{< / highlight >}}

![assembly instructions](/c_poly_cast3.png)

{{< highlight asm >}}
    x = numbers[1]->type;
    
    0x400624 <main+103>     mov    -0x8(%rbp),%rax
    (gdb) info registers rax
    rax            0x602010 6299664
    
    0x400628 <main+107>     add    $0x8,%rax
    (gdb) info registers rax
    rax            0x602018 6299672
    
    0x40062c <main+111>     mov    (%rax),%rax
    (gdb) x/2wx 0x602018
    0x602018:       0xffffe3c0      0x00007fff
    
    (gdb) x/wx 0x7fffffffe3c0
    0x7fffffffe3c0: 0x00000001
    
    0x40062f <main+114>     mov    (%rax),%eax
    (gdb) info registers rax
    rax            0x7fffffffe3c0   140737488348096
    
    (gdb) info registers eax
    eax            0x1      1
    
    0x400631 <main+116>     mov    %eax,-0x24(%rbp)
    (gdb) x/wx $rbp-0x24
    0x7fffffffe3ac: 0x00000001
{{< / highlight >}}

![assembly instructions](/c_poly_cast4.png)

### Conclusion

Class inheritance in C is not as elegant/easy as it is in other languages, but it can be achieved. Anyway, as we saw above, there're several pitfalls that could cause damage to you system. Such technique must be used diligently.

### References

*   [https://en.wikipedia.org/wiki/Call\_stack#Structure](https://en.wikipedia.org/wiki/Call_stack#Structure)
*   [http://flash-gordon.me.uk/ansi.c.txt](http://flash-gordon.me.uk/ansi.c.txt)
*   [http://svn.python.org/view/](http://svn.python.org/view/)
