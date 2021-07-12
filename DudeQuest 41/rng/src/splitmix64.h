#ifndef splitmix64_h
#define splitmix64_h

#include <stdint.h>
#include <time.h>

#ifdef DLIB_LOG_DOMAIN
#define printf dmLogInfo
#endif

class Splitmix64 {
public:
   static const uint32_t min = 0;
   static const uint32_t max = ~uint32_t(0);

   Splitmix64() {
      uint64_t s = (uint64_t)time(NULL);
      seed(s);
      // printf("Splitmix64:%p created\n", this);
   }

   explicit Splitmix64(uint64_t s) {
      seed(s);
      // printf("Splitmix64:%p created\n", this);
   }

   ~Splitmix64() {
      // printf("Splitmix64:%p destroyed\n", this);
   }

   void seed(uint64_t seed) {
      state_ = seed;
   }

   uint32_t operator()() {
      uint64_t z = (state_ += UINT64_C(0x9E3779B97F4A7C15));
      z = (z ^ (z >> 30)) * UINT64_C(0xBF58476D1CE4E5B9);
      z = (z ^ (z >> 27)) * UINT64_C(0x94D049BB133111EB);
      return (uint32_t)((z ^ (z >> 31)) >> 32);
   }

private:
   uint64_t state_;
};

typedef Splitmix64 Generator;

#endif /* splitmix64_h */
