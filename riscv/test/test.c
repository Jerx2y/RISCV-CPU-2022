// 1  1029  171

#include "io.h"

int gcd(int x, int y) {
  if (x%y == 0) return y;
  else return gcd(y, x%y);
}

int main() {
    // outlln(gcd(10,1));
    outlln(gcd(34986,3087));
    // outlln(gcd(2907,1539));

//    int sum = 0;
//    for (int i = 1; i <= 20; ++i)
//        sum += i;
//    
//    outlln(sum);

    return 0;
}
