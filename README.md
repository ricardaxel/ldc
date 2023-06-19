INSTRUMENTED LDC
================

This project is forked from the official [LDC compiler](https://github.com/ldc-developers/ldc)
and adds an overhead that give information about Garbage Collection.

This branch is currently based on version : *v1.32.0*

Usage
-----

- Build ldc compiler, druntime and phobos (see [Building from Sources](https://wiki.dlang.org/Building_LDC_from_source))
- compile your D program
- when executing binary, add the runtime argument "--DRT-gcopt=verbose:1".
Note : for now, this only works for non-forked single threaded GC, so you might
need to add theses runtime options as well : "--DRT-gcopt=fork:0 parallel:0"


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

