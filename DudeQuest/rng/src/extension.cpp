#define LIB_NAME "fastmath"
// #define DLIB_LOG_DOMAIN LIB_NAME

#include <dmsdk/sdk.h>
//#include <dmsdk/vectormath/cpp/vectormath_aos.h>
// #include "FastNoise.h"

#include <limits>
// #include "discrete_distribution.h"
#include "uniform_int_distribution.h"
#include "uniform_real_distribution.h"
#include "bernoulli_distribution.h"
#include "normal_distribution.h"

#define UNIFORM_INT_T "rng.uniform_int"
#define UNIFORM_REAL_T "rng.uniform_real"
#define BERNOULLI_T "rng.bernoulli"
// #define FAST_DISCRETE "rng.fast_discrete"
#define NORMAL_T "rng.normal"
#define GENERATOR_T "rng.generator"

static Generator g;
static const char Generator_key = 'g';

static
int generator_free(lua_State *L) {
   delete *static_cast<Generator **>(luaL_checkudata(L, 1, GENERATOR_T));
   return 0;
}

static
int generator_new(lua_State *L) {
   if (lua_gettop(L) > 0) {
      long seed = luaL_checklong(L, 1);
      *static_cast<Generator **>(lua_newuserdata(L, sizeof(Generator *))) = new Generator(seed);
   } else {
      *static_cast<Generator **>(lua_newuserdata(L, sizeof(Generator *))) = new Generator();
   }
   if (luaL_newmetatable(L, GENERATOR_T)) {
      static const luaL_Reg funcs[] = {
         {"__gc", generator_free},
         {NULL, NULL}
      };
      luaL_register(L, NULL, funcs);
   }
   lua_setmetatable(L, -2);
   return 1;
}

// static
// int discrete_distribution_next(lua_State *L) {
//    Generator& g = **(Generator **)lua_touserdata(L, lua_upvalueindex(1));
//    const fast_discrete_distribution& d = **(fast_discrete_distribution **)lua_touserdata(L, lua_upvalueindex(2));
//    lua_pushinteger(L, d(g) + 1);
//    return 1;
// }
// 
// static
// int discrete_distribution_free(lua_State *L) {
//    delete *static_cast<fast_discrete_distribution **>(luaL_checkudata(L, 1, FAST_DISCRETE));
//    return 0;
// }
// 
// static
// int discrete_distribution(lua_State *L) {
//    luaL_checktype(L, 1, LUA_TTABLE);
//    size_t count = lua_objlen(L, 1);
// 
//    std::vector<double> weights;
//    if (count > 0) {
//       bool ok = false;
//       for (unsigned int i = 1; i <= count; ++i) {
//          lua_rawgeti(L, 1, i);
//          double w = lua_tonumber(L, -1);
//          luaL_argcheck(L, w >= 0, 1, "all weights shall be non-negative values");
//          ok = ok ? true : w > 0;
//          weights.push_back(w);
//          lua_pop(L, 1);
//       }
//       luaL_argcheck(L, ok, 1, "at least one weight must be positive");
//    } else {
//       weights.push_back(1.0);
//    }
// 
//    if (lua_gettop(L) > 1) {
//       luaL_checkudata(L, 2, GENERATOR_T);
//    } else {
//       lua_pushlightuserdata(L, (void *)&Generator_key);
//       lua_gettable(L, LUA_REGISTRYINDEX);
//    }
// 
//    *static_cast<fast_discrete_distribution **>(lua_newuserdata(L, sizeof(fast_discrete_distribution *))) = new fast_discrete_distribution(weights);
//    if (luaL_newmetatable(L, FAST_DISCRETE)) {
//       static const luaL_Reg funcs[] = {
//          {"__gc", discrete_distribution_free},
//          {NULL, NULL}
//       };
//       luaL_register(L, NULL, funcs);
//    }
//    lua_setmetatable(L, -2);
// 
//    lua_pushcclosure(L, &discrete_distribution_next, 2);
//    return 1;
// }

static
int bernoulli_distribution_next(lua_State *L) {
   Generator& g = **(Generator **)lua_touserdata(L, lua_upvalueindex(1));
   const BernoulliDistribution& d = **(BernoulliDistribution **)lua_touserdata(L, lua_upvalueindex(2));
   lua_pushboolean(L, d(g));
   return 1;
}

static
int bernoulli_distribution_free(lua_State *L) {
   delete *static_cast<BernoulliDistribution **>(luaL_checkudata(L, 1, BERNOULLI_T));
   return 0;
}

static
int bernoulli_distribution(lua_State *L) {
   double p = luaL_checknumber(L, 1);
   luaL_argcheck(L, ((p >= 0.0) && (p <= 1.0)), 1, "p shall be a value between 0.0 and 1.0 (both included)");

   if (lua_gettop(L) > 1) {
      luaL_checkudata(L, 3, GENERATOR_T);
   } else {
      lua_pushlightuserdata(L, (void *)&Generator_key);
      lua_gettable(L, LUA_REGISTRYINDEX);
   }

   *static_cast<BernoulliDistribution **>(lua_newuserdata(L, sizeof(BernoulliDistribution *))) = new BernoulliDistribution(p);
   if (luaL_newmetatable(L, BERNOULLI_T)) {
      static const luaL_Reg funcs[] = {
         {"__gc", bernoulli_distribution_free},
         {NULL, NULL}
      };
      luaL_register(L, NULL, funcs);
   }
   lua_setmetatable(L, -2);

   lua_pushcclosure(L, &bernoulli_distribution_next, 2);
   return 1;
}

static
int uniform_int_distribution_next(lua_State *L) {
   Generator& g = **(Generator **)lua_touserdata(L, lua_upvalueindex(1));
   const UniformIntDistribution& d = **(UniformIntDistribution **)lua_touserdata(L, lua_upvalueindex(2));
   lua_pushinteger(L, d(g));
   return 1;
}

static
int uniform_int_distribution_free(lua_State *L) {
   delete *static_cast<UniformIntDistribution **>(luaL_checkudata(L, 1, UNIFORM_INT_T));
   return 0;
}

static
int uniform_int_distribution(lua_State *L) {
   lua_Integer a = luaL_checkinteger(L, 1);
   lua_Integer b = luaL_checkinteger(L, 2);
   // luaL_argcheck(L, (uint64_t(b - a + 1) <= std::numeric_limits<uint32_t>::max()), 1, "interval too large");

   if (lua_gettop(L) > 2) {
      luaL_checkudata(L, 3, GENERATOR_T);
   } else {
      lua_pushlightuserdata(L, (void *)&Generator_key);
      lua_gettable(L, LUA_REGISTRYINDEX);
   }

   *static_cast<UniformIntDistribution **>(lua_newuserdata(L, sizeof(UniformIntDistribution *))) = new UniformIntDistribution(a, b);
   if (luaL_newmetatable(L, UNIFORM_INT_T)) {
      static const luaL_Reg funcs[] = {
         {"__gc", uniform_int_distribution_free},
         {NULL, NULL}
      };
      luaL_register(L, NULL, funcs);
   }
   lua_setmetatable(L, -2);

   lua_pushcclosure(L, &uniform_int_distribution_next, 2);
   return 1;
}

static
int uniform_real_distribution_next(lua_State *L) {
   Generator& g = **(Generator **)lua_touserdata(L, lua_upvalueindex(1));
   const UniformRealDistribution& d = **(UniformRealDistribution **)lua_touserdata(L, lua_upvalueindex(2));
   lua_pushnumber(L, d(g));
   return 1;
}

static
int uniform_real_distribution_free(lua_State *L) {
   delete *static_cast<UniformRealDistribution **>(luaL_checkudata(L, 1, UNIFORM_REAL_T));
   return 0;
}

static
int uniform_real_distribution(lua_State *L) {
   double a = luaL_checknumber(L, 1);
   double b = luaL_checknumber(L, 2);
   luaL_argcheck(L, a <= b, 1, "b shall be greater than or equal to a");

   if (lua_gettop(L) > 2) {
      luaL_checkudata(L, 3, GENERATOR_T);
   } else {
      lua_pushlightuserdata(L, (void *)&Generator_key);
      lua_gettable(L, LUA_REGISTRYINDEX);
   }

   *static_cast<UniformRealDistribution **>(lua_newuserdata(L, sizeof(UniformRealDistribution *))) = new UniformRealDistribution(a, b);
   if (luaL_newmetatable(L, UNIFORM_REAL_T)) {
      static const luaL_Reg funcs[] = {
         {"__gc", uniform_real_distribution_free},
         {NULL, NULL}
      };
      luaL_register(L, NULL, funcs);
   }
   lua_setmetatable(L, -2);

   lua_pushcclosure(L, &uniform_real_distribution_next, 2);
   return 1;
}

static
int normal_distribution_next(lua_State *L) {
   Generator& g = **(Generator **)lua_touserdata(L, lua_upvalueindex(1));
   const NormalDistribution& d = **(NormalDistribution **)lua_touserdata(L, lua_upvalueindex(2));
   lua_pushnumber(L, d(g));
   return 1;
}

static
int normal_distribution_free(lua_State *L) {
   delete *static_cast<NormalDistribution **>(luaL_checkudata(L, 1, NORMAL_T));
   return 0;
}

static
int normal_distribution(lua_State *L) {
   double mean = luaL_checknumber(L, 1);
   double stddev = luaL_checknumber(L, 2);
   luaL_argcheck(L, stddev > 0, 2, "standard deviation shall be a positive value");

   if (lua_gettop(L) > 2) {
      luaL_checkudata(L, 3, GENERATOR_T);
   } else {
      lua_pushlightuserdata(L, (void *)&Generator_key);
      lua_gettable(L, LUA_REGISTRYINDEX);
   }

   *static_cast<NormalDistribution **>(lua_newuserdata(L, sizeof(NormalDistribution *))) = new NormalDistribution(mean, stddev);
   if (luaL_newmetatable(L, NORMAL_T)) {
      static const luaL_Reg funcs[] = {
         {"__gc", normal_distribution_free},
         {NULL, NULL}
      };
      luaL_register(L, NULL, funcs);
   }
   lua_setmetatable(L, -2);

   lua_pushcclosure(L, &normal_distribution_next, 2);
   return 1;
}

static
int vector3_get_components(lua_State *L) {
   Vectormath::Aos::Vector3 const *vec = dmScript::CheckVector3(L, 1);
   lua_pushnumber(L, vec->getX());
   lua_pushnumber(L, vec->getY());
   lua_pushnumber(L, vec->getZ());
   return 3;
}

static
int vector3_get_xy(lua_State *L) {
   Vectormath::Aos::Vector3 const *vec = dmScript::CheckVector3(L, 1);
   lua_pushnumber(L, vec->getX());
   lua_pushnumber(L, vec->getY());
   return 2;
}

static
int vector3_get_x(lua_State *L) {
   Vectormath::Aos::Vector3 const *vec = dmScript::CheckVector3(L, 1);
   lua_pushnumber(L, vec->getX());
   return 1;
}

static
int vector3_get_y(lua_State *L) {
   Vectormath::Aos::Vector3 const *vec = dmScript::CheckVector3(L, 1);
   lua_pushnumber(L, vec->getY());
   return 1;
}

static
int vector3_get_z(lua_State *L) {
   Vectormath::Aos::Vector3 const *vec = dmScript::CheckVector3(L, 1);
   lua_pushnumber(L, vec->getZ());
   return 1;
}

static
int vector3_get_sign_x(lua_State *L) {
   Vectormath::Aos::Vector3 const *vec = dmScript::CheckVector3(L, 1);
   double x = vec->getX();
   lua_pushnumber(L, (x < 0 ? -1 : (x > 0 ? 1 : 0)));
   return 1;
}

static
int vector3_set_components(lua_State *L) {
   Vectormath::Aos::Vector3 *const vec = dmScript::CheckVector3(L, 1);
   switch (lua_gettop(L)) {
      case 1: {
         vec->setX(0.0);
         vec->setY(0.0);
         vec->setZ(0.0);
         break;
      }
      case 2: {
         double x = luaL_checknumber(L, 2);
         vec->setX(x);
         break;
      }
      case 3: {
         double x = luaL_checknumber(L, 2);
         double y = luaL_checknumber(L, 3);
         vec->setX(x);
         vec->setY(y);
         break;
      }
      case 4: {
         double x = luaL_checknumber(L, 2);
         double y = luaL_checknumber(L, 3);
         double z = luaL_checknumber(L, 4);
         vec->setX(x);
         vec->setY(y);
         vec->setZ(z);
         break;
      }
      default: return luaL_error(L, "wrong number of arguments");
   }
   return 0;
}

static
int vector3_set_x(lua_State *L) {
   Vectormath::Aos::Vector3 *const vec = dmScript::CheckVector3(L, 1);
   double x = luaL_checknumber(L, 2);
   vec->setX(x);
   // vec->setX((float)luaL_checknumber(L, 2));
   return 0;
}

static
int vector3_set_y(lua_State *L) {
   Vectormath::Aos::Vector3 *const vec = dmScript::CheckVector3(L, 1);
   double y = luaL_checknumber(L, 2);
   vec->setY(y);
   return 0;
}

static
int vector3_set_z(lua_State *L) {
   Vectormath::Aos::Vector3 *const vec = dmScript::CheckVector3(L, 1);
   double z = luaL_checknumber(L, 2);
   vec->setZ(z);
   return 0;
}

static
int vector3_set_xy(lua_State *L) {
   Vectormath::Aos::Vector3 *const vec = dmScript::CheckVector3(L, 1);
   double x = luaL_checknumber(L, 2);
   double y = luaL_checknumber(L, 3);
   vec->setX(x);
   vec->setY(y);
   return 0;
}

static
int vector3_set_xyz(lua_State *L) {
   Vectormath::Aos::Vector3 *const vec = dmScript::CheckVector3(L, 1);
   double x = luaL_checknumber(L, 2);
   double y = luaL_checknumber(L, 3);
   double z = luaL_checknumber(L, 4);
   vec->setX(x);
   vec->setY(y);
   vec->setZ(z);
   return 0;
}

static
int vector3_add_components(lua_State *L) {
   Vectormath::Aos::Vector3 *const vec = dmScript::CheckVector3(L, 1);
   switch (lua_gettop(L)) {
      case 1: {
         // no-op
         break;
      }
      case 2: {
         double x = luaL_checknumber(L, 2);
         vec->setX(vec->getX() + x);
         break;
      }
      case 3: {
         double x = luaL_checknumber(L, 2);
         double y = luaL_checknumber(L, 3);
         vec->setX(vec->getX() + x);
         vec->setY(vec->getY() + y);
         break;
      }
      case 4: {
         double x = luaL_checknumber(L, 2);
         double y = luaL_checknumber(L, 3);
         double z = luaL_checknumber(L, 4);
         vec->setX(vec->getX() + x);
         vec->setY(vec->getY() + y);
         vec->setZ(vec->getZ() + z);
         break;
      }
      default: return luaL_error(L, "wrong number of arguments");
   }
   return 0;
}

static
int vector3_mult_z(lua_State *L) {
   Vectormath::Aos::Vector3 *const vec = dmScript::CheckVector3(L, 1);
   double k = luaL_checknumber(L, 2);
   vec->setZ(vec->getZ() * k);
   return 0;
}

static
int vector3_mult_x(lua_State *L) {
   Vectormath::Aos::Vector3 *const vec = dmScript::CheckVector3(L, 1);
   double k = luaL_checknumber(L, 2);
   vec->setX(vec->getX() * k);
   return 0;
}

static
int vector3_set_z_sign(lua_State *L) {
   Vectormath::Aos::Vector3 *const vec = dmScript::CheckVector3(L, 1);
   double k = luaL_checknumber(L, 2);
   vec->setZ(fabs(vec->getZ()) * k);
   return 0;
}

static
int vector3_flip_x(lua_State *L) {
   Vectormath::Aos::Vector3 *const vec = dmScript::CheckVector3(L, 1);
   vec->setX(-vec->getX());
   return 0;
}

static
int vector4_get_components(lua_State *L) {
   Vectormath::Aos::Vector4 const *vec = dmScript::CheckVector4(L, 1);
   lua_pushnumber(L, vec->getX());
   lua_pushnumber(L, vec->getY());
   lua_pushnumber(L, vec->getZ());
   lua_pushnumber(L, vec->getW());
   return 4;
}

static
int vector4_set_components(lua_State *L) {
   Vectormath::Aos::Vector4 *const vec = dmScript::CheckVector4(L, 1);
   switch (lua_gettop(L)) {
      case 1: {
         vec->setX(0.0);
         vec->setY(0.0);
         vec->setZ(0.0);
         vec->setW(0.0);
         break;
      }
      case 2: {
         double x = luaL_checknumber(L, 2);
         vec->setX(x);
         break;
      }
      case 3: {
         double x = luaL_checknumber(L, 2);
         double y = luaL_checknumber(L, 3);
         vec->setX(x);
         vec->setY(y);
         break;
      }
      case 4: {
         double x = luaL_checknumber(L, 2);
         double y = luaL_checknumber(L, 3);
         double z = luaL_checknumber(L, 4);
         vec->setX(x);
         vec->setY(y);
         vec->setZ(z);
         break;
      }
      case 5: {
         double x = luaL_checknumber(L, 2);
         double y = luaL_checknumber(L, 3);
         double z = luaL_checknumber(L, 4);
         double w = luaL_checknumber(L, 5);
         vec->setX(x);
         vec->setY(y);
         vec->setZ(z);
         vec->setW(w);
         break;
      }
      default: return luaL_error(L, "wrong number of arguments");
   }
   return 0;
}

static
int vector4_set_xy(lua_State *L) {
   Vectormath::Aos::Vector4 *const vec = dmScript::CheckVector4(L, 1);
   double x = luaL_checknumber(L, 2);
   double y = luaL_checknumber(L, 3);
   vec->setX(x);
   vec->setY(y);
   return 0;
}

static
int vector4_set_xyzw(lua_State *L) {
   Vectormath::Aos::Vector4 *const vec = dmScript::CheckVector4(L, 1);
   double x = luaL_checknumber(L, 2);
   double y = luaL_checknumber(L, 3);
   double z = luaL_checknumber(L, 4);
   double w = luaL_checknumber(L, 5);
   vec->setX(x);
   vec->setY(y);
   vec->setZ(z);
   vec->setW(w);
   return 0;
}

static
int vector4_set_x(lua_State *L) {
   Vectormath::Aos::Vector4 *const vec = dmScript::CheckVector4(L, 1);
   double value = luaL_checknumber(L, 2);
   vec->setX(value);
   return 0;
}

static
int vector4_set_y(lua_State *L) {
   Vectormath::Aos::Vector4 *const vec = dmScript::CheckVector4(L, 1);
   double value = luaL_checknumber(L, 2);
   vec->setY(value);
   return 0;
}

static
int vector4_set_z(lua_State *L) {
   Vectormath::Aos::Vector4 *const vec = dmScript::CheckVector4(L, 1);
   double value = luaL_checknumber(L, 2);
   vec->setZ(value);
   return 0;
}

static
int vector4_set_w(lua_State *L) {
   Vectormath::Aos::Vector4 *const vec = dmScript::CheckVector4(L, 1);
   double value = luaL_checknumber(L, 2);
   vec->setW(value);
   return 0;
}

static
int matrix4_get_m00_m11(lua_State *L) {
   Vectormath::Aos::Matrix4 *const mat = dmScript::CheckMatrix4(L, 1);
   lua_pushnumber(L, mat->getElem(0, 0));
   lua_pushnumber(L, mat->getElem(1, 1));
   return 2;
}

static
int matrix4_set_translation(lua_State *L) { // m03, m13 (x, y)
   Vectormath::Aos::Matrix4 *const mat = dmScript::CheckMatrix4(L, 1);
   double m03 = luaL_checknumber(L, 2);
   double m13 = luaL_checknumber(L, 3);
   Vectormath::Aos::Vector3 tmp(-m03, -m13, 0);
   mat->setTranslation(tmp);
   return 0;
}

static
int angle_between(lua_State *L) {
   Vectormath::Aos::Vector3 *const vec1 = dmScript::CheckVector3(L, 1);
   Vectormath::Aos::Vector3 *const vec2 = dmScript::CheckVector3(L, 2);
   double result = acos(vec1->getX() * vec2->getX() + vec1->getY() * vec2->getY());
   lua_pushnumber(L, result);
   return 1;
}

static
int sincos(lua_State *L) {
   double angle = luaL_checknumber(L, 1);
   lua_pushnumber(L, sin(angle));
   lua_pushnumber(L, cos(angle));
   return 2;
}

static
int cosnsin(lua_State *L) {
   double angle = luaL_checknumber(L, 1);
   lua_pushnumber(L, cos(angle));
   lua_pushnumber(L, sin(angle));
   return 2;
}

static
int combined_is_equal(lua_State *L) {
   double a = luaL_checknumber(L, 1);
   double b = luaL_checknumber(L, 2);
   int result = fabs(a - b) < 0.0001 * (fabs(a) + fabs(b) + 1.0);
   lua_pushboolean(L, result);
   return 1;
}

static
int random_int(lua_State *L) {
   lua_Integer range = luaL_checkinteger(L, 1);
   lua_pushinteger(L, (long(uint64_t(g()) * uint64_t(range) >> 32) + 1));
   return 1;
}

// static
// int get_noise(lua_State *L) {
//    switch (lua_gettop(L)) {
//       case 1: {
//          double x = luaL_checknumber(L, 1);
//          lua_pushnumber(L, fastnoise.GetNoise(x, 0));
//          break;
//       }
//       case 2: {
//          double x = luaL_checknumber(L, 1);
//          double y = luaL_checknumber(L, 2);
//          lua_pushnumber(L, fastnoise.GetNoise(x, y));
//          break;
//       }
//       case 3: {
//          double x = luaL_checknumber(L, 1);
//          double y = luaL_checknumber(L, 2);
//          double z = luaL_checknumber(L, 3);
//          lua_pushnumber(L, fastnoise.GetNoise(x, y, z));
//          break;
//       }
//       default: return luaL_error(L, "wrong number of arguments");
//    }
//    return 1;
// }

static const
luaL_Reg rnglib[] = {
   {"generator", generator_new},
   {"uniform_int", uniform_int_distribution},
   {"uniform_real", uniform_real_distribution},
   {"bernoulli", bernoulli_distribution},
   // {"discrete", discrete_distribution},
   {"normal", normal_distribution},
   {"random_int", random_int},
   {"vector3_get_components", vector3_get_components},
   {"vector3_set_components", vector3_set_components},
   {"vector3_add_components", vector3_add_components},
   {"vector3_get_xy", vector3_get_xy},
   {"vector3_get_x", vector3_get_x},
   {"vector3_get_y", vector3_get_y},
   {"vector3_get_z", vector3_get_z},
   {"vector3_set_x", vector3_set_x},
   {"vector3_set_y", vector3_set_y},
   {"vector3_set_z", vector3_set_z},
   {"vector3_set_xy", vector3_set_xy},
   {"vector3_set_xyz", vector3_set_xyz},
   {"vector3_mult_z", vector3_mult_z},
   {"vector3_mult_x", vector3_mult_x},
   {"vector3_set_z_sign", vector3_set_z_sign},
   {"vector3_get_sign_x", vector3_get_sign_x},
   {"vector3_flip_x", vector3_flip_x},
   {"vector4_get_components", vector4_get_components},
   {"vector4_set_components", vector4_set_components},
   {"vector4_set_xy", vector4_set_xy},
   {"vector4_set_xyzw", vector4_set_xyzw},
   {"vector4_set_x", vector4_set_x},
   {"vector4_set_y", vector4_set_y},
   {"vector4_set_z", vector4_set_z},
   {"vector4_set_w", vector4_set_w},
   {"matrix4_get_m00_m11", matrix4_get_m00_m11},
   {"matrix4_set_translation", matrix4_set_translation},
   {"angle_between", angle_between},
   {"sincos", sincos},
   {"cosnsin", cosnsin},
   {"combined_is_equal", combined_is_equal},
   // {"get_noise", get_noise},
   {NULL, NULL}
};

static
dmExtension::Result DefoldRNG_init(dmExtension::Params* params) {
   lua_State *L = params->m_L;

   lua_pushlightuserdata(L, (void *)&Generator_key);
   *static_cast<Generator **>(lua_newuserdata(L, sizeof(Generator *))) = new Generator();
   if (luaL_newmetatable(L, GENERATOR_T)) {
      static const luaL_Reg funcs[] = {
         {"__gc", generator_free},
         {NULL, NULL}
      };
      luaL_register(L, NULL, funcs);
   }
   lua_setmetatable(L, -2);
   lua_settable(L, LUA_REGISTRYINDEX);

   luaL_register(L, LIB_NAME, rnglib);
   lua_pop(L, 1);

   return dmExtension::RESULT_OK;
}

static
dmExtension::Result DefoldRNG_final(dmExtension::Params* params) {
   return dmExtension::RESULT_OK;
}

DM_DECLARE_EXTENSION(DefoldRNG, LIB_NAME, NULL, NULL, DefoldRNG_init, NULL, NULL, DefoldRNG_final)
