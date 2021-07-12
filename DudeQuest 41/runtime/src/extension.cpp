#define LIB_NAME "runtime"
#define DLIB_LOG_DOMAIN LIB_NAME

#include <dmsdk/sdk.h>

static
int get_context(lua_State *L) {
   dmScript::GetInstance(L);
   return 1;
}

static
int set_context(lua_State *L) {
   dmScript::SetInstance(L);
   return 0;
}

static
int execute_in_context(lua_State *L) {
   dmScript::GetInstance(L);
   int self = dmScript::Ref(L, LUA_REGISTRYINDEX);

   lua_pushvalue(L, 2);
   dmScript::SetInstance(L);

   lua_call(L, lua_gettop(L) - 1, LUA_MULTRET);
   int results_count = lua_gettop(L);

   lua_rawgeti(L, LUA_REGISTRYINDEX, self);
   dmScript::SetInstance(L);
   dmScript::Unref(L, LUA_REGISTRYINDEX, self);

   return results_count;
}

static const
luaL_Reg lib[] = {
   {"get_context", get_context},
   {"set_context", set_context},
   {"execute_in_context", execute_in_context},
   {NULL, NULL}
};

static
dmExtension::Result Initialize(dmExtension::Params *params) {
   lua_State *L = params->m_L;

   luaL_register(L, LIB_NAME, lib);
   lua_pop(L, 1);

   return dmExtension::RESULT_OK;
}

static
dmExtension::Result Finalize(dmExtension::Params *params) {
   return dmExtension::RESULT_OK;
}

DM_DECLARE_EXTENSION(DefoldRuntime, LIB_NAME, NULL, NULL, Initialize, NULL, NULL, Finalize)
