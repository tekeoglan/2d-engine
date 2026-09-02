package foundation_tests

import fo "../../engine/foundation"
import "core:math"
import "core:testing"

// These tests are behavioral names and TODO bodies, not supplied solutions.

@(test)
vec2_add_combines_matching_components :: proc(t: ^testing.T) {
	v1 := fo.Vec2{3, 1}
	v2 := fo.Vec2{1, 3}
	v3 := fo.vec2_add(v1, v2)
	testing.expect(t, v3.x == 4 && v3.y == 4, "vector addition is incorrect")
}

vec2_normalize_rejects_zero_length_input :: proc(t: ^testing.T) {
	panic("TODO(milestone 1 test): specify zero-vector normalization behavior")
}

@(test)
rect_overlaps :: proc(t: ^testing.T) {
	recLeft := fo.Rect{fo.Vec2{0, 0}, fo.Vec2{4, 4}}
	recRight := fo.Rect{fo.Vec2{5, 5}, fo.Vec2{6, 6}}
	testing.expect(t, !fo.rect_overlaps(recLeft, recRight), "Should not detect the collision")

	recLeft = fo.Rect{fo.Vec2{4, 3}, fo.Vec2{8, 7}}
	recRight = fo.Rect{fo.Vec2{0, 0}, fo.Vec2{12, 4}}
	testing.expect(
		t,
		fo.rect_overlaps(recLeft, recRight),
		"Should detect the little rectangle which goes through the middle of the big rectangle",
	)
	// Symetry
	testing.expect(t, fo.rect_overlaps(recRight, recLeft), "Should detect the symmetric operation")

	recLeft = fo.Rect{fo.Vec2{0, 0}, fo.Vec2{4, 4}}
	recRight = fo.Rect{fo.Vec2{1, 1}, fo.Vec2{2, 2}}
	testing.expect(
		t,
		fo.rect_overlaps(recRight, recLeft),
		"Should detect the detect the rect inside the another rect",
	)
	// Symetry
	testing.expect(
		t,
		fo.rect_overlaps(recLeft, recRight),
		"Should detect the detect the rect inside the another rect",
	)
}

mat3_transform_point_test :: proc(t: ^testing.T) {
	s := fo.Mat3{{2, 0, 0}, {0, 4, 0}, {0, 0, 1}}
	vec := fo.Vec2{1, 1}
	res := fo.mat3_transform_point(s, vec)
	testing.expect(t, res.x == 2 && res.y == 4, "Incorrect scaling factor")
}

@(test)
transform_2d_matrix_scales_rotates_then_translates :: proc(t: ^testing.T) {
	transform := fo.Transform_2D{
		position = fo.Vec2{10, 20},
		rotation_radians = math.PI / 2,
		scale = fo.Vec2{2, 3},
	}

	transformed_point := fo.mat3_transform_point(
		fo.transform_2d_matrix(transform),
		fo.Vec2{1, 1},
	)
	epsilon: f32 = 0.0001

	testing.expect(
		t,
		math.abs(transformed_point.x - 7) < epsilon && math.abs(transformed_point.y - 22) < epsilon,
		"transform matrix must scale, rotate, then translate the point",
	)
}
