---
title: "Force 2D Array Memory Layout"
date: 2021-01-14T08:13:17Z
tags: ["C"]
---

In this example, ref https://stackoverflow.com/a/59691323,
> ```C
> int a1[2][2] = {{142,143}, {144,145}};
> int **a2 = (int* []){ (int []){242,243}, (int []){244,245} };
> ```
> `a1` is a homogeneous 2D array with plain continuous layout in memory and expression `(int*)a1` is evaluated to a pointer to its first element:
> ```
> a1 --> 142 143 144 145
> ```
> `a2` is initialized from a heterogeneous 2D array and is a pointer to a value of type `int*`, i.e. dereference expression `*a2` evaluates into a value of type `int*`, memory layout does not have to be continuous:
> ```
> a2 --> p1 p2
>        ...
> p1 --> 242 243
>        ...
> p2 --> 244 245
> ```
> 
> The code usually crashes at run-time when array of type int[N][M] is type-casted and then accessed as type int**, for example:
> 
> ```C
> ((int**)a1)[1][0]   //crash on dereference of a value of type 'int'
> ```

What if I want to have memory layout of `a2` to have continuous memory layout?

Case like JNI, I want to pass the address to `a3[0]` to Java and let it parse all four integers. 

```C
int** a3 = (int **)calloc(4, sizeof(int));
for (int i = 0, byte_offset = 0; i < 4; i++) {
    memcpy(
        a3[0] + byte_offset,
        a1[i],
        sizeof(int)
    );
    a3[i] = a3[0] + byte_offset;
    byte_offset += sizeof(int);
}
```


## Hint For Debug

**Errors happen frequently during memory copy. To fix error data, try to trace the object/memory passed by each function call to find out when it gets copied.**

## Snippet For Print Memory

If print char which is unprintable, may casue terminal to print unreadable chars, fix it by `reset` [[ref](https://www.cyberciti.biz/tips/bash-fix-the-display.html)].

```C
static void print_hex(const char *s, u_int8_t len)
{
    char buf[1000] = "";
    int i = 0;
    for (; i < 3*len && i < 999; i += 3, s++) {
        sprintf(buf + i, "%02x ", (unsigned int)*s);
    }
    buf[i] = '\0';
    fprintf(stderr, "%s", buf);
}

static void printable(const char *s, u_int8_t len)
{
    char buf[1000] = "";
    int i = 0;
    for (; i < 999 && i < len; i++, s++) {
        if (isprint(*s)) {
            sprintf(buf + i, "%c", *s);
        } else {
            sprintf(buf + i, ".");
        }
    }
    buf[i] = '\0';
    fprintf(stderr, "%s", buf);
}
```

## Refs.

https://stackoverflow.com/questions/4593907/difference-between-strncpy-and-memcpy
> The difference is that memcpy will copy all N characters you ask for, while strncpy will copy up to the first null terminator inclusive, or N characters, whichever is fewer. (If it copies less than N characters, it will pad the rest out with null characters.)
>
> There's another difference as well, strncpy will fill the rest of the space with 0. e.g. if you do strncpy(a,b,255); and a is 10 long, strncpy will copy those 10 characters and fill the remaining 240 characters with 0. 

https://stackoverflow.com/a/47050610
> ```C
> char **AllocateAndDeepCopy(char **arr1, int arr1size) 
> {
>     unsigned int    i;
>     char            **arr2;
> 
>     /* Allocate string array */
>     arr2 = new char*[arr1size];
> 
>     /* Iterate array elements */
>     for (i=0; i<arr1size; i++) {
>         /* Allocate string */
>         arr2[i] = new char[strlen(arr1[i])+1];
> 
>         /* Copy contents */
>         strcpy(arr2[i], arr1[i]);
>     }   
> 
>     return arr2;
> }
> ```
