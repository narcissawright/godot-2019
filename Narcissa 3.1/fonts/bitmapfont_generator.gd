extends ColorRect
# run this code to generate the font.
func _ready():
	var font = BitmapFont.new()
	var font_img = load("res://fonts/bitmapfont.png")
	font.add_texture(font_img)
	var widths = [
#		  ,  !,  ",  #,  $,    %,  &,  ',  (,  ),
		5,  2,  4,  8,  7,   10,  9,  1,  4,  4,
#		 *,  +,  ,,  -,  .,    /,  0,  1,  2,  3,
		 5,  8,  3,  8,  3,    6,  7,  7,  7,  7,
#		 4,  5,  6,  7,  8,    9,  :,  ;,  <,  =,
		 7,  7,  7,  7,  7,    7,  3,  3,  6,  7,
#		 >,  ?,  @,  A,  B,    C,  D,  E,  F,  G,
		 6,  8, 10,  7,  7,    7,  7,  6,  6,  7,
#		 H,  I,  J,  K,  L,    M,  N,  O,  P,  Q,
		 7,  4,  6,  7,  6,    9,  7,  8,  7,  8,
#		 R,  S,  T,  U,  V,    W,  X,  Y,  Z,  [,
		 7,  7,  8,  7,  7,    8,  7,  8,  8,  5,
#		 \,  ],  ^,  _,  `,    a,  b,  c,  d,  e,
		 6,  5,  7,  9,  4,    6,  6,  6,  6,  6,
#		 f,  g,  h,  i,  j,    k,  l,  m,  n,  o,
		 5,  6,  6,  2,  3,    6,  3,  8,  6,  6,
#		 p,  q,  r,  s,  t,    u,  v,  w,  x,  y,
		 6,  6,  6,  6,  4,    6,  6,  8,  7,  6,
#		 z,  {,  |,  },  ~
		 6,  5,  3,  5,  8
	]
	font.set_height(14)
	for i in range (32, 127):
		var width = widths[i-32] + 2
		#                         starting point            size
		font.add_char(i, 0, Rect2(Vector2(0, i*14), Vector2(width, 14)))
	ResourceSaver.save("res://fonts/font.tres",font)