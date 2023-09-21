#!/usr/bin/env rdmd

import std.array;
import std.algorithm;
import std.conv;
import std.format;
import std.traits;
import std.regex;
import std.stdio;
import std.utf;

struct AllocInfo 
{
  string location;
  ulong totalSize;
  ulong numOfAlloc;

  void addAllocation(ulong size)
  {
    totalSize += size;
    numOfAlloc += 1;
  }

  float meanSize()
  {
    return totalSize.to!float / numOfAlloc;
  }

  string toString() 
  {
    return format!("%s --> Total : %s, Num of Allocs : %u, Mean size : %s")
                  (location, prettySizeOf(this.totalSize),
                   numOfAlloc, prettySizeOf(this.meanSize()));
  }
}

class AllocationRegistry
{
  AllocInfo[string] allocations;

  // [../../meson_include/rex-full/avs3/perf/tesla/avs3_perf_scenario.d:415] alloc 'rt.aaA.Impl' (56 bytes) => p = 0x7fc8f2f60040
  void addAllocationInfo(in char[] line)
  {
    auto locationRegex = ctRegex!(`\[.+?\]`);
    auto sizeRegex = ctRegex!(`(?: \()(\d*) (?:bytes\))`);

    auto locationCapture = line.matchFirst(locationRegex);

    if(!locationCapture)
      return;

    auto location = locationCapture.hit.to!string;

    auto sizeCapture = line.matchFirst(sizeRegex);
    if(!sizeCapture)
      return;

    auto size = sizeCapture[1].to!uint;

    allocations.require(location, AllocInfo(location, size, 0));

    allocations[location].addAllocation(size);
  }


  void dumpSummary()
  {
    writeln(allocations.values
               .sort!((a, b) => a.totalSize > b.totalSize)
               .map!(a => a.toString())
               .join("\n"));
  }
}


int main(string[] argv)
{
  if(argv.length != 2)
  {
    stderr.writefln("Usage : %s filename", argv[0]);
    return 1;
  }

  auto filename = argv[1];

  auto allocationRegistry = new AllocationRegistry();
  
  File file = File(filename);

  foreach(line; file.byLine)
  {
    try
      allocationRegistry.addAllocationInfo(line);
    catch(std.utf.UTFException e)
      continue;
  }

  allocationRegistry.dumpSummary();

  return 0;
}

string prettySizeOf(Num)(Num size)
  if(isNumeric!Num)
{
  float fsize = size.to!float;
  foreach(unit; ["b", "Kb", "Mb"])
  {
    if(fsize < 1024)
      return format!"%3.1f%s"(fsize, unit);
    fsize /= 1024;
  }

  return format!"%.1f%s"(fsize, "Gb");
}

