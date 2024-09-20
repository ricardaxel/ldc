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

