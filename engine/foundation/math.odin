package foundation

// vec2_add returns the component-wise sum of left and right.
//
// Preconditions: none. Postcondition: inputs are unchanged.
// Ownership/lifetime: inputs and result are copied; no allocation occurs.
// Failure: none. Thread: safe on any thread because no shared state is used.
// Research: `2D vector component wise addition`.
vec2_add :: proc(left, right: Vec2) -> Vec2 {
	panic("TODO(milestone 1): implement vec2_add")
}

// vec2_subtract returns right subtracted component-wise from left.
//
// Preconditions: none. Postcondition: inputs are unchanged.
// Ownership/lifetime: inputs and result are copied; no allocation occurs.
// Failure: none. Thread: safe on any thread because no shared state is used.
// Research: `2D displacement vector subtraction order`.
vec2_subtract :: proc(left, right: Vec2) -> Vec2 {
	panic("TODO(milestone 1): implement vec2_subtract")
}

// vec2_multiply_scalar scales both components by scalar.
//
// Preconditions: none. Postcondition: inputs are unchanged.
// Ownership/lifetime: inputs and result are copied; no allocation occurs.
// Failure: none. Thread: safe on any thread because no shared state is used.
// Research: `vector scalar multiplication geometry`.
vec2_multiply_scalar :: proc(value: Vec2, scalar: f32) -> Vec2 {
	panic("TODO(milestone 1): implement vec2_multiply_scalar")
}

// vec2_dot returns the dot product of left and right. A dot product measures
// directional similarity and is later useful for projections and collision.
//
// Preconditions: none. Postcondition: inputs are unchanged.
// Ownership/lifetime: inputs and result are copied; no allocation occurs.
// Failure: none. Thread: safe on any thread because no shared state is used.
// Research: `2D vector dot product geometric meaning`.
vec2_dot :: proc(left, right: Vec2) -> f32 {
	panic("TODO(milestone 1): implement vec2_dot")
}

// vec2_length_squared returns length multiplied by itself. Comparing squared
// lengths avoids a square root when the exact length is unnecessary.
//
// Preconditions: none. Postcondition: the result is nonnegative.
// Ownership/lifetime: input and result are copied; no allocation occurs.
// Failure: none. Thread: safe on any thread because no shared state is used.
// Research: `squared vector magnitude avoid square root`.
vec2_length_squared :: proc(value: Vec2) -> f32 {
	panic("TODO(milestone 1): implement vec2_length_squared")
}

// vec2_length returns the Euclidean length of value.
//
// Preconditions: none. Postcondition: the result is nonnegative.
// Ownership/lifetime: input and result are copied; no allocation occurs.
// Failure: none. Thread: safe on any thread because no shared state is used.
// Research: `Euclidean norm 2D vector`.
vec2_length :: proc(value: Vec2) -> f32 {
	panic("TODO(milestone 1): implement vec2_length")
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
	panic("TODO(milestone 1): implement vec2_normalize")
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
	panic("TODO(milestone 1): implement rect_contains_point")
}

// rect_overlaps reports whether two rectangles have a positive-area overlap.
// Rectangles that only touch at an edge do not overlap.
//
// Precondition: both rectangles satisfy their min/max invariant.
// Postcondition: inputs are unchanged. Failure: none.
// Ownership/lifetime: inputs are copied; no allocation occurs.
// Thread: safe on any thread because no shared state is used.
// Research: `AABB overlap separating axis edge touching`.
rect_overlaps :: proc(left, right: Rect) -> bool {
	panic("TODO(milestone 1): implement rect_overlaps")
}

// mat3_identity returns the identity transformation, which leaves points
// unchanged when multiplied by them.
//
// Preconditions: none. Postcondition: diagonal values are one and others zero.
// Ownership/lifetime: result is copied; no allocation occurs.
// Failure: none. Thread: safe on any thread because no shared state is used.
// Research: `3x3 identity matrix homogeneous coordinates`.
mat3_identity :: proc() -> Mat3 {
	panic("TODO(milestone 1): implement mat3_identity")
}

// mat3_multiply returns `left * right` for column-vector transforms. Applying
// the result to a point therefore applies right first and left second.
//
// Preconditions: none. Postcondition: inputs are unchanged.
// Ownership/lifetime: inputs and result are copied; no allocation occurs.
// Failure: none. Thread: safe on any thread because no shared state is used.
// Research: `column major matrix composition order transform`.
mat3_multiply :: proc(left, right: Mat3) -> Mat3 {
	panic("TODO(milestone 1): implement mat3_multiply")
}

// mat3_transform_point applies a homogeneous 2D transformation to point.
//
// Preconditions: transform_matrix is affine and follows Mat3's storage rule.
// Postcondition: the point is treated as a column vector with homogeneous w=1.
// Ownership/lifetime: inputs and result are copied; no allocation occurs.
// Failure: none. Thread: safe on any thread because no shared state is used.
// Research: `homogeneous 2D matrix transform point w coordinate`.
mat3_transform_point :: proc(transform_matrix: Mat3, point: Vec2) -> Vec2 {
	panic("TODO(milestone 1): implement mat3_transform_point")
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
	panic("TODO(milestone 1): implement transform_2d_matrix")
}
