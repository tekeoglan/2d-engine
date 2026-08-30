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

identity_matrix_leaves_point_unchanged :: proc(t: ^testing.T) {
	panic("TODO(milestone 1 test): specify identity transformation behavior")
}

transform_composition_has_documented_order :: proc(t: ^testing.T) {
	panic("TODO(milestone 1 test): verify scale, then rotation, then translation")
}
