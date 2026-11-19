// expect: add-field path must be a field's path, ending in its name (a string), got: ().
// The path names the new field, not the object that gets it.
#import "../../lib.typ": add-field, object, string
#add-field(object((a: string())), (), string())
