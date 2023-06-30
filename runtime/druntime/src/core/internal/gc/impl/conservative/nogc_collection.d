// basic vector implementation that doesn't use GC and phobos
// not optimized at all !
module core.internal.gc.impl.conservative.nogc_collection;

import core.stdc.stdlib : malloc, realloc, free;

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

  ref inout(T) opIndex(size_t idx) inout @nogc
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

@nogc nothrow unittest
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

struct LinkedList(T)
{
  private struct Cell(T)
  {
    T data;
    Cell* next;
  }

  void pushAtFront(T elem) @nogc
  {
    Cell!T * newCell = cast(Cell!T *)malloc((Cell!T).sizeof);

    newCell.data = elem;
    newCell.next = m_FirstCell;
    m_FirstCell = newCell;
    
    m_Length++;
  }

  void remove(size_t idx) @nogc
  {
    assert(idx < m_Length);

    if(idx == 0)
    {
      Cell!T* toDelete = m_FirstCell;
      m_FirstCell = m_FirstCell.next;
      free(toDelete);
    }
    
    else
    {
      Cell!T* precCell = m_FirstCell;
      Cell!T* curCell = precCell.next;
      size_t curIdx = 1;

      while(curIdx++ != idx)
      {
        precCell = curCell;
        curCell = curCell.next;
      }

      precCell.next = curCell.next;
      free(curCell);
    }

    m_Length--;
  }

  ref inout(T) opIndex(size_t idx) inout @nogc
  {
    assert(idx < m_Length);

    // double pointer to ensure this method is const
    inout(Cell!T *)* curCell = &m_FirstCell;
    size_t curIdx = 0;

    while(curIdx++ != idx)
      curCell = &(*curCell).next;

    return (*curCell).data;
  }

  void opIndexAssign(T value, size_t idx) @nogc
  {
    assert(idx < m_Length);
    Cell!T * curCell = m_FirstCell;
    size_t curIdx = 0;

    while(curIdx++ != idx)
      curCell = curCell.next;
  
    curCell.data = value;
  }

  // /!\ push at front
  void opOpAssign(string op = "~")(T value) @nogc
  {
    this.pushAtFront(value);
  }

  int opApply(int delegate(const(T)) nothrow @nogc op) const nothrow @nogc
  {
    int res = 0;

    const(Cell!T *)* curCell = &m_FirstCell;
    for(size_t i = 0; i < length; i++)
    {
      res = op((*curCell).data);
      if(res)
        break;
      curCell = &(*curCell).next;
    }

    return res;
  }

  bool contains(in T value) const @nogc
  {
    const(Cell!T *)* curCell = &m_FirstCell;
    for(size_t i = 0; i < length; i++)
    {
      if((*curCell).data == value)
        return true;
      curCell = &(*curCell).next;
    }

    return false;
  }

  // don't call this.contains() to avoid a useless pass
  size_t firstIndexOf(in T value) const @nogc
  {
    const(Cell!T *)* curCell = &m_FirstCell;
    for(size_t i = 0; i < length; i++)
    {
      if((*curCell).data == value)
        return i;
      curCell = &(*curCell).next;
    }

    assert(0);
  }

  size_t length() const @nogc { return m_Length; }

private:
  Cell!T * m_FirstCell;
  size_t m_Length;
}

@nogc nothrow unittest
{
  LinkedList!int ll;

  foreach_reverse(i; 3 .. 10)
    ll.pushAtFront(i);

  assert(ll[0] == 3);
  assert(ll.firstIndexOf(3) == 0);

  assert(ll[5] == 8);
  ll[5] = 7;
  assert(ll[5] == 7);
  ll[5] = 8;

  assert(ll[6] == 9);
  assert(ll.firstIndexOf(9) == 6);

  assert(ll.contains(3));
  assert(!ll.contains(2));

  assert(ll.length == 7);

  ll ~= 1;
  assert(ll.firstIndexOf(1) == 0);
  assert(ll.length == 8);

  ll.pushAtFront(1);
  assert(ll.firstIndexOf(1) == 0);
  assert(ll.length == 9);

  ll.remove(0);
  ll.remove(0);
  assert(ll.length == 7);
  assert(ll[0] == 3);

  assert(ll[3] == 6);
  ll.remove(3);
  assert(ll.length == 6);
  assert(ll[2] == 5);
  assert(ll[3] == 7);
  assert(ll[4] == 8);

  // remove last
  ll.remove(5);
  assert(ll[4] == 8);
  assert(ll.length == 5);

  {
    LinkedList!int ll2;
    foreach_reverse(i; 0 .. 5)
      ll2.pushAtFront(i);

    int currIdx = 0;
    foreach(elem; ll2)
      assert(elem == currIdx++);
  }
}

struct NoGCAssociativeArray(Key, Value)
{
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
  
    size_t idx = m_Keys.firstIndexOf(key);
    m_Keys.remove(idx);
    m_Values.remove(idx);
  }

  bool exists(in Key key) const @nogc
  {
    return m_Keys.contains(key);
  }

  inout(Value) opIndex(inout Key key) inout @nogc
  {
    assert(exists(key));
    return m_Values[m_Keys.firstIndexOf(key)];
  }

  // can modify value, not key
  int opApply(int delegate(Key, ref Value) nothrow @nogc op) nothrow @nogc
  {
    int res = 0;

    for(size_t i = 0; i < m_Keys.length; i++)
    {
      Key key = m_Keys[i];
      Value val = m_Values[i];
      res = op(key, val);

      m_Values[i] = val;
      if(res)
        break;
    }

    return res;
  }

  private:
    LinkedList!Key m_Keys;
    LinkedList!Value m_Values;
}

@nogc nothrow unittest
{
  NoGCAssociativeArray!(void*, int) aa;
  
  auto p1 = malloc(1);
  auto p2 = malloc(1);
  auto p3 = malloc(1);

  aa.insert(p1, 1);
  aa.insert(p2, 2);

  assert(aa.exists(p1));
  assert(!aa.exists(p3));

  assert(aa[p1] == 1);
  assert(aa[p2] == 2);

  aa.remove(p2);
  assert(!aa.exists(p2));
  assert(aa[p1] == 1);

  aa.insert(p2, 2);
  aa.insert(p3, 3);
  
  auto pointers = cast(void**)malloc(3 * (void*).sizeof);
  scope(exit) free(pointers);
  pointers[0] = p3;
  pointers[1] = p2;
  pointers[2] = p1;

  int idx = 0;
  foreach(k, v; aa)
  {
    assert(k == pointers[idx]);
    assert(v == 3 - idx);
    idx++;
  }

  foreach(_, ref v; aa)
    v += 3;

  assert(aa[p1] == 4);
}
