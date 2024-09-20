import core.memory;
import std.stdio;

enum D1 = 2;
enum D2 = 3;
enum D3 = 4;

int main()
{
  /* long[][][] arr =  new long[][][] (5, 6 , 7); */
  long[][][] arr;

  long* ptr = cast(long*)arr.ptr;
  
  ptr = cast(long*)GC.malloc(D1 * D2 * D3 * long.sizeof);

  foreach(i; 0 .. D1 * D2 * D3)
    ptr[i] = i;

  writeln(arr);


  return 0;
}
