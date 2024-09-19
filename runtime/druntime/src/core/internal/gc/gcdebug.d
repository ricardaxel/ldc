module core.internal.gc.gcdebug;

import core.gc.config;
import core.stdc.stdio : vfprintf, stderr; // needed to output profiling results
import core.stdc.stdarg;

public:
extern(C) struct DebugInfo
{

  pure static DebugInfo alloc(string file, uint line, size_t size,
                         const string ti) nothrow @nogc
  {
    DebugInfo di;
    di.filename = file;
    di.line = line;
    di.size = size;
    di.dataType = ti;
    di.typeOfAllocation = TypeOfAllocation._alloc;

    return di;

  }

  pure static DebugInfo alloc(string file, uint line, size_t size,
                         const TypeInfo ti) nothrow @nogc
  {
    return DebugInfo.alloc(file, line, size, typeInfoToStr(ti));
  }

  pure static DebugInfo realloc(string file, uint line, size_t size,
                           const TypeInfo ti) nothrow @nogc
  {
    DebugInfo di;
    di.filename = file;
    di.line = line;
    di.size = size;
    di.dataType = typeInfoToStr(ti);
    di.typeOfAllocation = TypeOfAllocation._realloc;

    return di;
  }

  pure static DebugInfo arrayAlloc(string file, uint line, size_t size,
                              const TypeInfo ti) nothrow @nogc
  {
    DebugInfo di;
    di.filename = file;
    di.line = line;
    di.size = size;
    di.dataType = typeInfoToStr(ti);
    di.typeOfAllocation = TypeOfAllocation._array;

    return di;
  }

  static DebugInfo captureData(string file, uint line, size_t size,
                               string capturedData) nothrow @nogc
  {
    DebugInfo di;
    di.filename = file;
    di.line = line;
    di.size = size;
    di.capturedData = capturedData;
    di.typeOfAllocation = TypeOfAllocation._captureData;

    return di;
  }


  private enum TypeOfAllocation {
    _alloc,
    _realloc,
    _array,
    _captureData, // from delegate
  }

  TypeOfAllocation typeOfAllocation;

  void printAllocation(void* p) nothrow @nogc
  {
    enum treshold = 2;

    verbose_printf(treshold, "[%s:%d] ", filename.ptr, line);
    final switch(typeOfAllocation) with(TypeOfAllocation)
    {
    case _alloc:
      verbose_printf(treshold, "alloc");
      verbose_printf(treshold, " '%s' (%lu bytes)", dataType.ptr, size);
      break;
    case _realloc:
      verbose_printf(treshold, "realloc");
      verbose_printf(treshold, " '%s' (%lu bytes)", dataType.ptr, size);
      break;
    case _array:
      verbose_printf(treshold, "new array of");
      verbose_printf(treshold, " '%s' (%lu bytes)", dataType.ptr, size);
      break;
    case _captureData:
      verbose_printf(treshold, "captured data");
      verbose_printf(treshold, " '%s' (%lu bytes)", capturedData.ptr, size);
      break;
    }

    verbose_printf(treshold, " => p = %p\n", p);
  }

  void printMarking(void* p, void* poolBase, void* poolTop, ulong bin) nothrow @nogc
  {
    enum treshold = 3;

    verbose_printf(treshold, "\t\tmarking ");
    printDataDescription(treshold, p);
    verbose_printf(treshold, "\t\t--> p belongs to pool [%p .. %p]\n", poolBase, poolTop);
    verbose_printf(treshold, "\t\t--> SmallAlloc : Bin #%u\n", bin);
  }

  void printFreeing(void* p) nothrow @nogc
  {
    enum treshold = 2;

    verbose_printf(treshold, "\tFreeing ");
    printDataDescription(treshold);

    import core.internal.gc.impl.conservative.gc : numCollections;
    verbose_printf(treshold, " -- AGE : %u/%u\n", age, numCollections + 1);
  }


  void printDataDescription(const int treshold, void* p = null) nothrow @nogc
  {
    final switch(typeOfAllocation) with(TypeOfAllocation)
    {
    case _alloc:
    case _realloc:
      verbose_printf(treshold, "%s", dataType.ptr);
      break;
    case _array:
      verbose_printf(treshold, "array of %s", dataType.ptr);
      break;
    case _captureData:
      verbose_printf(treshold, "captured data %s", capturedData.ptr);
      break;
    }

    verbose_printf(treshold, " (%s:%d; %lu bytes)", filename.ptr, line, size);

    if(p)
      verbose_printf(treshold, " (%p)", p);
  }

  void incrementAge() nothrow @nogc { age++; }

  // TODO make them private
  string filename;
  uint line;

private:

  size_t size;

  string dataType;
  string capturedData;

  uint age; // gains one year per collection
}

/* ============================ VERBOSE PRINTF =============================== */

extern(C) void verbose_printf(uint treshold, scope const char* format, scope const ...) @system nothrow @nogc
{
  if(config.verbose >= treshold)
  {
    va_list args;
    va_start (args, format);
    vfprintf(stderr, format, args);
    va_end(args);
  }
}

pure string typeInfoToStr(const(TypeInfo) ti) nothrow @nogc
{
    string name;
    if (ti is null)
        name = "null";
    else if (auto ci = cast(TypeInfo_Class)ti)
        name = ci.name;
    else if (auto si = cast(TypeInfo_Struct)ti)
        name = si.mangledName; // .name() might GC-allocate, avoid deadlock
    else if (auto ci = cast(TypeInfo_Const)ti)
        static if (__traits(compiles,ci.base)) // different whether compiled with object.di or object.d
            return typeInfoToStr(ci.base);
        else
            return typeInfoToStr(ci.next);
    else
        name = typeid(ti).name;


    // special cases
    if(name == "S2rt3aaA4Impl")
      return "rt.aaA.Impl";
    else if(name == "S2rt3aaA6Bucket")
      return "rt.aaA.Bucket";
    else if(name == "S2rt3aaA__T5EntryZ")
      return "AA Entry";

    // see typeinfo.d
    // TODO mixin version ?
    else if(name == "TypeInfo_i")
      return "int";
    else if(name == "TypeInfo_k")
      return "uint";
    else if(name == "TypeInfo_m")
      return "ulong";
    else if(name == "TypeInfo_l")
      return "long";
    else if(name == "TypeInfo_h")
      return "ubyte";
    else if(name == "TypeInfo_b")
      return "bool";
    else if(name == "TypeInfo_g")
      return "byte";
    else if(name == "TypeInfo_a")
      return "char";
    else if(name == "TypeInfo_t")
      return "ushort";
    else if(name == "TypeInfo_s")
      return "short";
    else if(name == "TypeInfo_u")
      return "wchar";
    else if(name == "TypeInfo_w")
      return "dchar";

    // floating points types
    else if(name == "TypeInfo_f")
      return "float";
    else if(name == "TypeInfo_d")
      return "double";
    else if(name == "TypeInfo_e")
      return "real";

    return name;
}
