#ifndef bernoulli_distribution_h
#define bernoulli_distribution_h

#include "splitmix64.h"

class BernoulliDistribution {
public:
   BernoulliDistribution(double p) : p_(p) {}
   
   bool operator()(Generator& g) const {
      return 0x1.0p-32 * g() < p_;
   }
   
private:
   double p_;
};

#endif /* bernoulli_distribution_h */
