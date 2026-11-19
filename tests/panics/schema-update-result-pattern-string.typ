// expect: schema-update result field "pattern" must be a regex (string() compiles a string pattern), got: "^[A-Z]".
// A string stored as a pattern would match as literal text (`match` with
// a string is a substring test), so the node is refused, not misread.
#import "../../lib.typ": schema-update, object, string
#schema-update(object((a: string())), ("a",), s => (..s, pattern: "^[A-Z]"))
