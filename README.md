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

### Using `new` :

- [x] new Class (_d_allocclass)
```
class C { ... }
C c = new C(); // _d_allocclass
```

<details>
<summary><b>Note</b></summary>
dmd use `_d_allocclass` to allocate class. One can find such function in ldc runtime, but it is never directly called from generated IR 

![image](https://github.com/ricardaxel/ldc/assets/46921637/d021494b-7d24-4320-ac74-da3bdc1ef1a6)
</details>

- [ ] `new`  uninitialized non-array item (_d_newitemU / _d_newitemT / _d_newitemiT)
```
struct Sz {int x = 0;}
struct Si {int x = 3;}

new Sz(); // _d_newitemT(typeid(Sz)) 
new Si(); // _d_newitemiT(typeid(Si))
```
- [ ] `new` basic type (_d_allocmemoryT)

```
auto a = new int; // _d_allocmemoryT
```

- [x] `new` associative array (_aaNew) : See Associative Array section for more details
```
int[float] aa = new int[float]; // __aaNew
```

### Array :

- [x] new array (_d_newarrayU / _d_newarrayT / _d_newarrayiT)
```
int[] arr = new int[3]; // `_d_newarrayT` : initializes to 0
float[] arr2 = new float[3]; // `_d_newarrayiT` : initializes based on initializer retrieved from TypeInfo
int[] arr3 = [1, 2, 3]; // `_d_newarrayU` :  leave elements uninitialized (compiler set them just after allocation=
double[] arr = uninitializedArray!(double[])(100); // call `_d_newarrayU` under the hood
```
- [x] array length set (_d_arraysetlengthT / _d_arraysetlengthiT)  (partially handled, would need better log info)
```
int[] arr;
arr.length = 2; // _d_arraysetlengthT
```
- [x] array append (_d_arrayappendT / _d_arrayappendcTX / _d_arrayappendcd / _d_arrayappendwd)  (partially handled, would need better log info)
```
int[] a = [1, 2, 3];
a ~= 1; // _d_arrayappendcTX
a ~= [1, 2]; // _d_arrayappendT
```

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

- [ ] Slice copy (_d_array_slice_copy)
```
int[] b = new int[3];
b[0 .. $] = [1, 2, 3]; // _d_array_slice_copy
```

### Delegates

- [x] Allocation of local variable captured by a delegate
```
void f()
{
	int a = 3;
	int b = 2;

	// trigger a GC allocation to store a and b
	// allocation made with _d_allocmemory, at the entry of the function f()	
  	auto dg = () => a + b; 
}
```

### Associative Arrays

- [ ] AA initialization : Assocative Arrays is a pointer to a struct called 'Impl' (in reports this struct is mangled to S2rt3aaA4Impl),
so initializiation will trigger some allocation.

AAs also holds an array of buckets, which get sometimes resized or shrinked.
For example, when an AA is created, 8 buckets are allocated.

```
double[int] aa;
aa[0] = 0; // __aGetY => (lazy) initialization 
	   // => allocation of Impl.sizeof bytes (56 bytes in v1.32.0)
	   //  + allocation of 8 * Bucket.sizeof bytes (128 bytes)
	   //  + allocation of entry (see next point)
	   
string[float] aa2 = new string[float]; // __aaNew => allocation of 56 + 128 bytes 
 
 ```

- [x] new entry added (__aaGetY)
```
double[int] aa;
aa[0] = 0; // new entry ==> allocation of (Key.sizeof + Value.sizeof) bytes 
aa[0] = 1; // already allocated ==> nothing to do
 ```

- [ ] AA initialization with litteral (_d_assocarrayliteralTX)
```
double[int] aa = [1: 2, 3: 4, 5: 6]; // _d_assocarrayliteralTX
```

- [ ] entry deletion (__aaDelX) : if new version of aa is 'short' enough, it will be shrinked, which implies a reallocation 
- [ ] rehash (object.d:rehash --> __aaRehash) 

 
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


╰─> ldc2 -g -O0 test3.d --disable-gc2stack --disable-d-passes --of test3

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


