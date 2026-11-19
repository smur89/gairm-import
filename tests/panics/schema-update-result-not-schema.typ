// expect: schema-update result must be a schema, got: none.
// A function that forgets to return the node.
#import "../../lib.typ": schema-update, object, string
#schema-update(object((a: string())), ("a",), s => { let _ = s })
