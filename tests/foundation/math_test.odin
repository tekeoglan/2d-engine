package foundation_tests

import "core:testing"
import foundation "../../engine/foundation"

_ :: foundation

// These tests are behavioral names and TODO bodies, not supplied solutions.

@(test)
vec2_add_combines_matching_components :: proc(t: ^testing.T) {
	panic("TODO(milestone 1 test): specify vec2_add examples and assertions")
}

vec2_normalize_rejects_zero_length_input :: proc(t: ^testing.T) {
	panic("TODO(milestone 1 test): specify zero-vector normalization behavior")
}

rect_touching_only_at_max_edge_does_not_overlap :: proc(t: ^testing.T) {
	panic("TODO(milestone 1 test): specify half-open rectangle edge behavior")
}

@(test)
mat3_multiply_returns_left_times_right_for_column_major_matrices :: proc(t: ^testing.T) {
	// Mat3 literals are written as columns: the first index is the column and
	// the second index is the row.
	left := fo.Mat3{
		{1, 0, 5},
		{2, 1, 6},
		{3, 4, 0},
	}
	right := fo.Mat3{
		{-2, 3, 4},
		{1, 0, 5},
		{0, 0, 1},
	}
	expected := fo.Mat3{
		{16, 19, 8},
		{16, 20, 5},
		{3, 4, 0},
	}

	actual := fo.mat3_multiply(left, right)
	testing.expect(t, actual == expected, "mat3 multiplication returned an incorrect product")
}

identity_matrix_leaves_point_unchanged :: proc(t: ^testing.T) {
	panic("TODO(milestone 1 test): specify identity transformation behavior")
}

transform_composition_has_documented_order :: proc(t: ^testing.T) {
	panic("TODO(milestone 1 test): verify scale, then rotation, then translation")
}
