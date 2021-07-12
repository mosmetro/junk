// C++ implementation of a fast algorithm for generating samples from a
// discrete distribution.
//
// David Pal, December 2015
// https://github.com/DavidPal/discrete-distribution

#ifndef discrete_distribution_h
#define discrete_distribution_h

#include <vector>
#include <numeric>
#include <cmath>
#include "splitmix64.h"

namespace {
   // Stack that does not own the underlying storage.
   template<typename T, typename BidirectionalIterator>
   class stack_view {
   public:
      stack_view(const BidirectionalIterator base) : base_(base), top_(base) {};
      
      void push(const T& element) {
         *top_ = element;
         ++top_;
      }
      
      T pop() {
         --top_;
         return *top_;
      }
      
      bool empty() {
         return top_ == base_;
      }
      
   private:
      const BidirectionalIterator base_;
      BidirectionalIterator top_;
   };
}

class fast_discrete_distribution {
public:
   fast_discrete_distribution(const std::vector<double>& weights) {
      printf("dd created\n");
      normalize_weights(weights);
      create_buckets();
   }
   
   ~fast_discrete_distribution() {
      printf("dd destroyed\n");
   }
   
   int operator()(Generator& g) const {
      const double number = 0x1.0p-32 * g();
      unsigned int index = floor(buckets_.size() * number);
      
      const Bucket& bucket = buckets_[index];
      if (number < bucket.c) {
         return bucket.a;
      } else {
         return bucket.b;
      }
   }
   
   void normalize_weights(const std::vector<double>& weights) {
      const double sum = std::accumulate(weights.begin(), weights.end(), 0.0);
      const size_t s = weights.size();
      probabilities_.reserve(s);
      for (unsigned int i = 0; i < s; ++i) {
         probabilities_.push_back(weights[i] / sum);
      }
   }
   
   void create_buckets() {
      const size_t N = probabilities_.size();
      const double recipN = 1.0 / N;
      
      // Two stacks in one vector.  First stack grows from the begining of the
      // vector. The second stack grows from the end of the vector.
      std::vector<Segment> segments(N);
      stack_view<Segment, std::vector<Segment>::iterator> small(segments.begin());
      stack_view<Segment, std::vector<Segment>::reverse_iterator> large(segments.rbegin());
      
      // Split probabilities into small and large
      for (unsigned int i = 0; i < N; ++i) {
         const double p = probabilities_[i];
         if (p < recipN) {
            small.push(Segment(p, i));
         } else {
            large.push(Segment(p, i));
         }
      }
      
      buckets_.reserve(N);
      
      int i = 0;
      while (!small.empty() && !large.empty()) {
         const Segment s = small.pop();
         const Segment l = large.pop();
         
         // Create a mixed bucket
         const Bucket m = { s.second, l.second, s.first + static_cast<double>(i) / N };
         buckets_.push_back(m);
         
         // Calculate the length of the left-over segment
         const double left_over = s.first + l.first - recipN;
         
         // Re-insert the left-over segment
         if (left_over < recipN) {
            small.push(Segment(left_over, l.second));
         } else {
            large.push(Segment(left_over, l.second));
         }
         
         ++i;
      }
      
      // Create pure buckets
      while (!large.empty()) {
         const Segment l = large.pop();
         // The last argument is irrelevant as long it's not a NaN
         const Bucket b = { l.second, l.second, 0.0 };
         buckets_.push_back(b);
      }
      
      // This loop can be executed only due to numerical inaccuracies
      // TODO: Find an example when it actually happens
      while (!small.empty()) {
         const Segment s = small.pop();
         // The last argument is irrelevant as long it's not a NaN
         const Bucket b = { s.second, s.second, 0.0 };
         buckets_.push_back(b);
      }
   }
private:
   typedef std::pair<double, int> Segment;
   typedef struct { int a; int b; double c; } Bucket;
   
   std::vector<double> probabilities_;
   std::vector<Bucket> buckets_;
};

#endif /* discrete_distribution_h */
