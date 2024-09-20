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
