package foundation

// Vec2 stores a two-dimensional value. Its meaning comes from its caller: it
// may represent a position, direction, velocity, or size.
Vec2 :: struct {
	x: f32,
	y: f32,
}

// Rect stores an axis-aligned rectangle in world or screen space.
//
// Invariant: min.x <= max.x and min.y <= max.y.
// Edge policy: min is inclusive and max is exclusive.
Rect :: struct {
	min: Vec2, // left and bottom,
	max: Vec2, // right and top,
}

// Color stores linear red, green, blue, and alpha channels in the inclusive
// range [0, 1]. The renderer milestone will decide where color-space conversion
// occurs; callers must not assume these are already display-encoded values.
Color :: struct {
	r: f32,
	g: f32,
	b: f32,
	a: f32,
}

// COLOR_* constants provide unambiguous values for tests and debug drawing.
COLOR_TRANSPARENT :: Color {
	r = 0,
	g = 0,
	b = 0,
	a = 0,
}
COLOR_BLACK :: Color {
	r = 0,
	g = 0,
	b = 0,
	a = 1,
}
COLOR_WHITE :: Color {
	r = 1,
	g = 1,
	b = 1,
	a = 1,
}

// Transform_2D describes translation, counter-clockwise rotation in radians,
// and scale in world space. A negative scale mirrors an object.
Transform_2D :: struct {
	position:         Vec2,
	scale:            Vec2,
	rotation_radians: f32,
}

// Mat3 is a column-major 3x3 matrix used for homogeneous 2D transformations.
// Homogeneous coordinates allow translation, rotation, and scale to be
// composed through matrix multiplication.
Mat3 :: [3][3]f32

Mat3_Identity :: Mat3{{1, 0, 0}, {0, 1, 0}, {0, 0, 1}}
