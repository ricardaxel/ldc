// basic vector implementation that doesn't use GC and phobos
// not optimized at all !

import core.stdc.stdlib : malloc, realloc, free;
/* import core.stdc.string : memcpy, memset, memmove; */

struct Vec(T)
{
  static opCall() @nogc
  {
    Vec!T v;
    v.m_Data = cast(T*)malloc(1 * T.sizeof);
    v.m_Length = 0;
    v.m_Capacity = 1;

    return v;
  }

  ~this() @nogc
  {
    if(m_Data)
      free(m_Data);
  }

  void push(T elem) @nogc
  {
    if(m_Length + 1 > m_Capacity)
    {
      m_Capacity *= 2;
      m_Data = cast(T*)realloc(m_Data, m_Capacity * T.sizeof);
    }

    m_Data[m_Length] = elem;
    m_Length++;
  }

  const(T) opIndex(size_t idx) const @nogc
  {
    assert(idx < m_Length);
    return m_Data[idx];
  }

  void opIndexAssign(T value, size_t idx) @nogc
  {
    assert(idx < m_Length);
    m_Data[idx] = value;
  }

  void opOpAssign(string op = "~")(T value) @nogc
  {
    this.push(value);
  }

  bool contains(in T value) const @nogc
  {
    for(size_t i = 0; i < length; i++)
      if(value == m_Data[i])
        return true;

    return false;
  }

  // don't call this.contains() to avoid a useless pass
  size_t firstIndexOf(in T value) const @nogc
  {
    for(size_t i = 0; i < length; i++)
      if(value == m_Data[i])
        return i;

    assert(0);
  }

  size_t length() const @nogc { return m_Length; }
  size_t capacity() const @nogc { return m_Capacity; }

private:
  T* m_Data;
  size_t m_Length;
  size_t m_Capacity;
}

unittest
{
  Vec!int v = Vec!int();

  foreach(i; 3 .. 10)
    v.push(i);

  assert(v[0] == 3);
  assert(v.firstIndexOf(3) == 0);

  assert(v[5] == 8);
  v[5] = 7;
  assert(v[5] == 7);

  assert(v[6] == 9);
  assert(v.firstIndexOf(9) == 6);

  assert(v.contains(3));
  assert(!v.contains(2));

  assert(v.length == 7);
  assert(v.capacity == 8);

  v ~= 1;
  assert(v.firstIndexOf(1) == 7);
  assert(v.length == 8);
  assert(v.capacity == 8);

  v.push(1);
  assert(v.firstIndexOf(1) == 7);
  assert(v.length == 9);
  assert(v.capacity == 16);
}

struct AssociativeArray(Key, Value)
{
  static opCall() @nogc
  {
    AssociativeArray!(Key, Value) aa;
    aa.m_Keys = Vec!Key();
    aa.m_Values = Vec!Value();
    return aa;
  }

  void insert(Key key, Value value) @nogc
  {
    if(m_Keys.contains(key))
    {
      size_t idx = m_Keys.firstIndexOf(key);
      m_Values[idx] = value;
    }
    else
    {
      m_Keys ~= key;
      m_Values ~= value;
    }
  }

  void remove(in Key key) @nogc
  {
    if(!m_Keys.contains(key))
      return;

    //very costy !
  }

  bool exists(in Key key) const @nogc
  {
    return m_Keys.contains(key);
  }

  Value opIndex(in Key key) const @nogc
  {
    assert(exists(key));
    return m_Values[m_Keys.firstIndexOf(key)];
  }

  private:
    Vec!Key m_Keys;
    Vec!Value m_Values;
}

unittest
{
  AssociativeArray!(void*, int) aa = AssociativeArray!(void*, int)();
  
  auto p1 = malloc(1);
  auto p2 = malloc(1);
  auto p3 = malloc(1);

  aa.insert(p1, 1);
  aa.insert(p2, 2);

  assert(aa.exists(p1));
  assert(!aa.exists(p3));

  assert(aa[p1] == 1);
  assert(aa[p2] == 2);
}
