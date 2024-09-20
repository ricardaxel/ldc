int main()
{
    int[] arr;
    arr.reserve(10);

    foreach(i; 0 .. 10)
        arr ~= i;

    return 0;
}
