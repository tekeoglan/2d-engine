package foundation

// vec2_add returns the component-wise sum of left and right.
//
// Allocation: none. Failure: none.
// Research: `2D vector component wise addition`.
vec2_add :: proc(left, right: Vec2) -> Vec2 {
	panic("TODO(milestone 1): implement vec2_add")
}

// vec2_subtract returns right subtracted component-wise from left.
//
// Allocation: none. Failure: none.
// Research: `2D displacement vector subtraction order`.
vec2_subtract :: proc(left, right: Vec2) -> Vec2 {
	panic("TODO(milestone 1): implement vec2_subtract")
}

// vec2_multiply_scalar scales both components by scalar.
//
// Allocation: none. Failure: none.
// Research: `vector scalar multiplication geometry`.
vec2_multiply_scalar :: proc(value: Vec2, scalar: f32) -> Vec2 {
	panic("TODO(milestone 1): implement vec2_multiply_scalar")
}

// vec2_dot returns the dot product of left and right. A dot product measures
// directional similarity and is later useful for projections and collision.
//
// Allocation: none. Failure: none.
// Research: `2D vector dot product geometric meaning`.
vec2_dot :: proc(left, right: Vec2) -> f32 {
	panic("TODO(milestone 1): implement vec2_dot")
}

// vec2_length_squared returns length multiplied by itself. Comparing squared
// lengths avoids a square root when the exact length is unnecessary.
//
// Allocation: none. Failure: none.
// Research: `squared vector magnitude avoid square root`.
vec2_length_squared :: proc(value: Vec2) -> f32 {
	panic("TODO(milestone 1): implement vec2_length_squared")
}

// vec2_length returns the Euclidean length of value.
//
// Allocation: none. Failure: none.
// Research: `Euclidean norm 2D vector`.
vec2_length :: proc(value: Vec2) -> f32 {
	panic("TODO(milestone 1): implement vec2_length")
}

// vec2_normalize returns a unit-length vector pointing in value's direction.
//
// Failure: returns Invalid_Argument for a zero-length input instead of
// producing NaN values. Allocation: none.
// Research: `normalize zero vector NaN`.
vec2_normalize :: proc(value: Vec2) -> (Vec2, Engine_Error) {
	panic("TODO(milestone 1): implement vec2_normalize")
}

// rect_contains_point reports whether point is inside rect using an inclusive
// minimum and exclusive maximum edge policy.
//
// Precondition: rect satisfies its min/max invariant. Allocation: none.
// Research: `half open rectangle point containment`.
rect_contains_point :: proc(rect: Rect, point: Vec2) -> bool {
	panic("TODO(milestone 1): implement rect_contains_point")
}

// rect_overlaps reports whether two rectangles have a positive-area overlap.
// Rectangles that only touch at an edge do not overlap.
//
// Precondition: both rectangles satisfy their min/max invariant.
// Research: `AABB overlap separating axis edge touching`.
rect_overlaps :: proc(left, right: Rect) -> bool {
	panic("TODO(milestone 1): implement rect_overlaps")
}

// mat3_identity returns the identity transformation, which leaves points
// unchanged when multiplied by them.
//
// Allocation: none. Failure: none.
// Research: `3x3 identity matrix homogeneous coordinates`.
mat3_identity :: proc() -> Mat3 {
	panic("TODO(milestone 1): implement mat3_identity")
}

// mat3_multiply composes two column-major transformations.
//
// Postcondition: the documented multiplication order must match all later
// transform callers. Allocation: none.
// Research: `column major matrix composition order transform`.
mat3_multiply :: proc(left, right: Mat3) -> Mat3 {
	panic("TODO(milestone 1): implement mat3_multiply")
}

// mat3_transform_point applies a homogeneous 2D transformation to point.
//
// Allocation: none. Failure: none for affine matrices.
// Research: `homogeneous 2D matrix transform point w coordinate`.
mat3_transform_point :: proc(transform_matrix: Mat3, point: Vec2) -> Vec2 {
	panic("TODO(milestone 1): implement mat3_transform_point")
}

// transform_2d_matrix creates a matrix from position, rotation, and scale.
//
// Postcondition: the chosen composition order must be documented by tests
// before hierarchical transforms depend on it.
// Research: `2D translation rotation scale matrix order`.
transform_2d_matrix :: proc(transform: Transform_2D) -> Mat3 {
	panic("TODO(milestone 1): implement transform_2d_matrix")
}
