package foundation

// Error_Kind categorizes expected failures without coupling callers to a
// subsystem's private backend error representation.
Error_Kind :: enum {
	None,
	Invalid_Argument,
	Out_Of_Memory,
	Invalid_Handle,
	Not_Found,
	Platform,
	Graphics,
	Audio,
	Decode,
	Internal,
}

// Engine_Error describes a recoverable failure.
//
// Ownership: message is borrowed. The producer must ensure it remains valid
// while the caller reads the error. Milestone 1 uses static messages only.
// An Error_Kind of None means no error occurred.
Engine_Error :: struct {
	kind:    Error_Kind,
	message: string,
}

// NO_ERROR is the canonical success value for procedures returning an
// Engine_Error alongside or instead of a result.
NO_ERROR :: Engine_Error{kind = .None, message = ""}
