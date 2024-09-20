import core.memory;
import std.stdio;

class Bar {}

class Foo { 
  this() { new Bar; }
}


void allocFoo()
{
  Foo f2 = new Foo;
}

void clearStack()
{
  int[2048] x;
}

void main()
{
  Foo f = new Foo; 
  allocFoo();

  int a = 2;
  auto dg = () => a++; // capturing a

  clearStack();
  GC.collect();
}

