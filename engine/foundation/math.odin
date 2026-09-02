package foundation

import "core:math"
// vec2_add returns the component-wise sum of left and right.
//
// Preconditions: none. Postcondition: inputs are unchanged.
// Ownership/lifetime: inputs and result are copied; no allocation occurs.
// Failure: none. Thread: safe on any thread because no shared state is used.
// Research: `2D vector component wise addition`.
vec2_add :: proc(left, right: Vec2) -> Vec2 {
	return Vec2{left.x + right.x, left.y + right.y}
}

// vec2_subtract returns right subtracted component-wise from left.
//
// Preconditions: none. Postcondition: inputs are unchanged.
// Ownership/lifetime: inputs and result are copied; no allocation occurs.
// Failure: none. Thread: safe on any thread because no shared state is used.
// Research: `2D displacement vector subtraction order`.
vec2_subtract :: proc(left, right: Vec2) -> Vec2 {
	return Vec2{right.x - left.x, right.y - left.y}
}

// vec2_multiply_scalar scales both components by scalar.
//
// Preconditions: none. Postcondition: inputs are unchanged.
// Ownership/lifetime: inputs and result are copied; no allocation occurs.
// Failure: none. Thread: safe on any thread because no shared state is used.
// Research: `vector scalar multiplication geometry`.
vec2_multiply_scalar :: proc(value: Vec2, scalar: f32) -> Vec2 {
	return Vec2{value.x * scalar, value.y * scalar}
}

// vec2_dot returns the dot product of left and right. A dot product measures
// directional similarity and is later useful for projections and collision.
//
// Preconditions: none. Postcondition: inputs are unchanged.
// Ownership/lifetime: inputs and result are copied; no allocation occurs.
// Failure: none. Thread: safe on any thread because no shared state is used.
// Research: `2D vector dot product geometric meaning`.
vec2_dot :: proc {
	vec2_dot_duo,
	vec2_dot_single,
}

@(private = "file")
vec2_dot_duo :: proc(left, right: Vec2) -> f32 {
	return (right.x * left.x) + (right.y * left.y)
}

@(private = "file")
vec2_dot_single :: proc(vec: Vec2) -> f32 {
	return (vec.x * vec.x) + (vec.y * vec.y)
}

// vec2_length_squared returns length multiplied by itself. Comparing squared
// lengths avoids a square root when the exact length is unnecessary.
//
// Preconditions: none. Postcondition: the result is nonnegative.
// Ownership/lifetime: input and result are copied; no allocation occurs.
// Failure: none. Thread: safe on any thread because no shared state is used.
// Research: `squared vector magnitude avoid square root`.
vec2_length_squared :: proc(value: Vec2) -> f32 {
	return vec2_dot_single(value)
}

// vec2_length returns the Euclidean length of value.
//
// Preconditions: none. Postcondition: the result is nonnegative.
// Ownership/lifetime: input and result are copied; no allocation occurs.
// Failure: none. Thread: safe on any thread because no shared state is used.
// Research: `Euclidean norm 2D vector`.
vec2_length :: proc(value: Vec2) -> f32 {
	return math.sqrt_f32(vec2_dot_single(value))
}

// vec2_normalize returns a unit-length vector pointing in value's direction.
//
// Preconditions: none; zero length is an expected failure, not an assertion.
// Failure: returns Invalid_Argument for a zero-length input instead of
// producing NaN values. Postcondition: success has approximately unit length.
// Ownership/lifetime: input and result are copied; no allocation occurs.
// Thread: safe on any thread because no shared state is used.
// Research: `normalize zero vector NaN`.
vec2_normalize :: proc(value: Vec2) -> (Vec2, Engine_Error) {
	if value.x == 0 && value.y == 0 {
		return Vec2{}, Engine_Error{.Invalid_Argument, "Vector length is zero."}
	}

	return vec2_multiply_scalar(value, vec2_length(value)), Engine_Error{.None, ""}
}

// rect_contains_point reports whether point is inside rect using an inclusive
// minimum and exclusive maximum edge policy.
//
// Precondition: rect satisfies its min/max invariant.
// Postcondition: inputs are unchanged. Failure: none.
// Ownership/lifetime: inputs are copied; no allocation occurs.
// Thread: safe on any thread because no shared state is used.
// Research: `half open rectangle point containment`.
rect_contains_point :: proc(rect: Rect, point: Vec2) -> bool {
	inRangeX := rect.min.x <= point.x && point.x < rect.max.x
	inRangeY := rect.min.y <= point.y && point.y < rect.max.y
	return inRangeX && inRangeY
}

// rect_overlaps reports whether two rectangles have a positive-area overlap.
// Rectangles that only touch at an edge do not overlap.
//
// Precondition: both rectangles satisfy their min/max invariant.
// Postcondition: inputs are unchanged. Failure: none.
// Ownership/lifetime: inputs are copied; no allocation occurs.
// Thread: safe on any thread because no shared state is used.
// Research: `AABB overlap separating axis edge touching`.
rect_overlaps :: proc(a, b: Rect) -> bool {
	isALeftToB := a.max.x < b.min.x
	isARightToB := a.min.x > b.max.x
	isAAbowB := a.min.y > b.max.y
	isABelowB := b.min.y > a.max.y
	return !(isALeftToB || isARightToB || isAAbowB || isABelowB)
}

// mat3_multiply returns `left * right` for column-vector transforms. Applying
// the result to a point therefore applies right first and left second.
//
// Preconditions: none. Postcondition: inputs are unchanged.
// Ownership/lifetime: inputs and result are copied; no allocation occurs.
// Failure: none. Thread: safe on any thread because no shared state is used.
// Research: `column major matrix composition order transform`.
mat3_multiply :: proc(left, right: Mat3) -> Mat3 {
	// m_r_c = sum(i to k) {a_r_i x b_i_c}
	m: Mat3
	for r := 0; r < 3; r += 1 {
		for c := 0; c < 3; c += 1 {
			for k := 0; k < 3; k += 1 {
				m[r][c] += left[r][k] * right[k][c]
			}
		}
	}

	return m
}

// mat3_transform_point applies a homogeneous 2D transformation to point.
//
// Preconditions: transform_matrix is affine and follows Mat3's storage rule.
// Postcondition: the point is treated as a column vector with homogeneous w=1.
// Ownership/lifetime: inputs and result are copied; no allocation occurs.
// Failure: none. Thread: safe on any thread because no shared state is used.
// Research: `homogeneous 2D matrix transform point w coordinate`.
mat3_transform_point :: proc(transform_matrix: Mat3, point: Vec2) -> Vec2 {
	m := mat3_multiply(transform_matrix, Mat3{{point.x, 0, 0}, {point.y, 0, 0}, {1, 0, 0}})
	v := Vec2{m[0][0], m[1][0]}
	return v
}

// transform_2d_matrix returns `translation * rotation * scale`, so a point is
// scaled first, rotated counter-clockwise in Y-up world space, then translated.
//
// Preconditions: all fields contain finite floating-point values.
// Postcondition: result follows Mat3's column-major storage rule.
// Ownership/lifetime: input and result are copied; no allocation occurs.
// Failure: none. Thread: safe on any thread because no shared state is used.
// Research: `2D translation rotation scale matrix order`.
transform_2d_matrix :: proc(transform: Transform_2D) -> Mat3 {
	//                | 1 0 t_x |
	// translation =  | 0 1 t_y |
	//                | 0 0 1   |
	//
	//             | cos -sin 0 |
	// rotation =  | sin cos 0 |
	//             | 0   0   1 |
	//
	//          | s_x 0 0 |
	// scale =  | 0 s_y 0 |
	//          | 0  0  1 |
	t := Mat3{{1, 0, transform.position.x}, {0, 1, transform.position.y}, {0, 0, 1}}
	r := Mat3 {
		{math.cos(transform.rotation_radians), -math.sin(transform.rotation_radians), 0},
		{math.sin(transform.rotation_radians), math.cos(transform.rotation_radians), 0},
		{0, 0, 1},
	}
	s := Mat3{{transform.scale.x, 0, 0}, {0, transform.scale.y, 0}, {0, 0, 1}}

	return mat3_multiply(mat3_multiply(t, r), s)
}
