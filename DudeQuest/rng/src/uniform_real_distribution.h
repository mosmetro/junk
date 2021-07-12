#ifndef uniform_real_distribution_h
#define uniform_real_distribution_h

#include "splitmix64.h"
#include <algorithm>

class UniformRealDistribution {
public:
   UniformRealDistribution(double a, double b) : a_(a), b_(b) {
      if (a_ > b_) {
         std::swap(a_, b_);
      }
   }

   double operator()(Generator& g) const {
      return 0x1.0p-32 * g() * (b_ - a_) + a_;
   }

private:
   double a_;
   double b_;
};

#endif /* uniform_real_distribution_h */
