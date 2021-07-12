-- export
return {
   -- event types
   POINTER_DOWN = hash("POINTER_DOWN"),
   POINTER_UP = hash("POINTER_UP"),
   POINTER_DRAGGED = hash("POINTER_DRAGGED"),
   POINTER_CANCELLED = hash("POINTER_CANCELLED"),

   -- actions
   LEFT = hash("left"),
   RIGHT = hash("right"),
   UP = hash("up"),
   DOWN = hash("down"),
   A = hash("a"),
   B = hash("b"),
   X = hash("x"),
   Y = hash("y"),
   PAUSE = hash("pause"),
   TOUCH = hash("touch"),
   MULTI_TOUCH = hash("multi_touch"),
   NO_ACTION = hash(""),

   -- render order
   CONTROLS = 0,
   BACKGROUND = 1,
   BELOW_MENU = 2,
   MENU = 3,
   ABOVE_MENU = 4,
   FOREGROUND = 15,
}
