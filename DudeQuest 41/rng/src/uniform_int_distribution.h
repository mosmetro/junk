#ifndef uniform_int_distribution_h
#define uniform_int_distribution_h

#include "splitmix64.h"
#include <algorithm>

class UniformIntDistribution {
public:
   UniformIntDistribution(long a, long b) : a_(a), b_(b) {
      if (a_ > b_) {
         std::swap(a_, b_);
      }
   }

   long operator()(Generator& g) const {
      uint32_t range = uint32_t(b_ - a_ + 1);
      return long(uint64_t(g()) * uint64_t(range) >> 32) + a_;
   }

private:
   long a_;
   long b_;
};

#endif /* uniform_int_distribution_h */
