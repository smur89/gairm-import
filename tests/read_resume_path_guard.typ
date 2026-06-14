// read-resume only accepts string paths starting with "/". Typst has
// no way to assert that a function panics, so the guards themselves
// are validated by reading lib.typ; this test just pins that the
// public symbol still exists with the expected signature.

#import "../lib.typ": read-resume

#let _ = read-resume
