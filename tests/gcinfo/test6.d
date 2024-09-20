int main()
{

  int[] arr;

  int[] arr2 = [1, 2, 3];
  int[] arr3 = [4, 5, 6];

  arr = arr2 ~ arr3;
  arr = arr ~ arr2 ~ arr3;

  return 0;
}
