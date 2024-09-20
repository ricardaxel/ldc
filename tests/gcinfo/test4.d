int main()
{
  long[][][] arr;
  initArr(arr, 5, 6, 7);

  return 0;
}

void initArr(ref long[][][] arr, long d1, long d2, long d3)
{
  arr = new long[][][] (d1, d2, d3);
}
