INSTRUMENTED LDC
================

This project is forked from the official [LDC compiler](https://github.com/ldc-developers/ldc)
and adds an overhead that give information about Garbage Collection.

This branch is currently based on version : *v1.32.0*, with a patch to compile with 
llvm-16 (see `git diff v1.32.0..v1.32.0-llvm16`)

Usage
-----

- Build ldc compiler, druntime and phobos (see [Building from Sources](https://wiki.dlang.org/Building_LDC_from_source))
- compile your D program
- when executing binary, add the runtime argument "--DRT-gcopt=verbose:1".
Note : for now, this only works for non-forked single threaded GC, so you might
need to add theses runtime options as well : "--DRT-gcopt=fork:0 parallel:0"

Allocations handling status
---------------------------

### Classes :

- [x] new Class (_d_allocclass)
```
class C { ... }
C c = new C();
```

### Array :

- [ ] 2 arrays concatenation (_d_arraycatT)
```
int[] x = [10, 20, 30];
int[] y = [40, 50];
int[] c = x ~ y; // _d_arraycatT(typeid(int[]), (cast(byte*) x)[0..x.length], (cast(byte*) y)[0..y.length]);
```

  - [ ] N (> 2) arrays concatenation (_d_arraycatnTX)
```
int[] a, b, c;
int[] res = a ~ b ~ c; // _d_arraycatnTX(typeid(int[]), [(cast(byte*)a.ptr)[0..a.length], (cast(byte*)b.ptr)[0..b.length], (cast(byte*)c.ptr)[0..c.length]]);
```

Example
-------

```
>> cat test2.d
import core.memory;

class Bar { int bar; }

class Foo {

  this()
  {
    this.bar = new Bar;
  }

  Bar bar;
}


void func()
{
  Foo f2 = new Foo;
  Foo f3 = new Foo;
}

int main()
{
  Foo f = new Foo; 

  func();
  GC.collect();

  return 0;
}

# compile without optimization
>> ldc2 -g -O0 test2.d --disable-gc2stack --disable-d-passes --of test2  

>> ./test2 "--DRT-gcopt=cleanup:collect fork:0 parallel:0 verbose:1"
[test2.d:24] new 'test2.Foo' (24 bytes) => p = 0x7fac0b381000
[test2.d:9] new 'test2.Bar' (20 bytes) => p = 0x7fac0b381020
[test2.d:18] new 'test2.Foo' (24 bytes) => p = 0x7fac0b381040
[test2.d:9] new 'test2.Bar' (20 bytes) => p = 0x7fac0b381060
[test2.d:19] new 'test2.Foo' (24 bytes) => p = 0x7fac0b381080
[test2.d:9] new 'test2.Bar' (20 bytes) => p = 0x7fac0b3810a0

============ COLLECTION (from :0)  =============
	============= SWEEPING ==============
=====================================================


============ COLLECTION (from :0)  =============
	============= SWEEPING ==============
	Freeing test2.Foo (test2.d:24; 24 bytes) (0x7fac0b381000). AGE :  1/2 
	Freeing test2.Bar (test2.d:9; 20 bytes) (0x7fac0b381020). AGE :  1/2 
	Freeing test2.Foo (test2.d:18; 24 bytes) (0x7fac0b381040). AGE :  1/2 
	Freeing test2.Bar (test2.d:9; 20 bytes) (0x7fac0b381060). AGE :  1/2 
	Freeing test2.Foo (test2.d:19; 24 bytes) (0x7fac0b381080). AGE :  1/2 
	Freeing test2.Bar (test2.d:9; 20 bytes) (0x7fac0b3810a0). AGE :  1/2 
=====================================================

```

Example (delegates)
-------------------

```
╰─> cat test3.d
import std.stdio;
import core.memory;

alias DG = void delegate();

DG captureDgData()
{
  int a = 3;

  // dg references local a ==> needs memory allocation
  auto dg = () { a++; };

  return dg;
}

void nestedCapture()
{
  DG c1 = captureDgData();
}

// clear stack
void clobber() { int[2048] x; }

void main()
{
  nestedCapture();
  DG c2= captureDgData();
  GC.collect();
}


╰─> ldc2 -g -O0 test3.d --disable-gc2stack --disable-d-passes --of test3.d

╰─> ./test3 "--DRT-gcopt=cleanup:collect fork:0 parallel:0 verbose:2" 
[test3.d:6] captured '[a]' (4 bytes) => p = 0x7f02638fe000
[test3.d:6] captured '[a]' (4 bytes) => p = 0x7f02638fe010

============ COLLECTION (from :0)  =============
        ============= SWEEPING ==============
        Freeing [a] (test3.d:6; 4 bytes (0x7f02638fe000). AGE :  0/1 
=====================================================


============ COLLECTION (from :0)  =============
        ============= SWEEPING ==============
        Freeing [a] (test3.d:6; 4 bytes (0x7f02638fe010). AGE :  1/2 
=====================================================


```


