#ifndef normal_distribution_h
#define normal_distribution_h

#include "splitmix64.h"

class NormalDistribution {
public:
   NormalDistribution(double mean, double stddev) : mean_(mean), stddev_(stddev) {}
   
   double operator()(Generator& g) const {
      double x1, x2, w, y1;
      static double y2;
      static int use_last = 0;
      
      // use value from previous call
      if (use_last) {
         y1 = y2;
         use_last = 0;
      } else {
         do {
            x1 = 2.0 * (0x1.0p-32 * g()) - 1.0;
            x2 = 2.0 * (0x1.0p-32 * g()) - 1.0;
            w = x1 * x1 + x2 * x2;
         } while (w >= 1.0);
         
         w = sqrt((-2.0 * log(w)) / w);
         y1 = x1 * w;
         y2 = x2 * w;
         use_last = 1;
      }
      
      return mean_ + y1 * stddev_;
   }
   
private:
   double mean_;
   double stddev_;
};

#endif /* normal_distribution_h */
