// expect: schema-put takes a schema, then a path (an array of segments); got an integer and a path.
#import "../../lib.typ": schema-put, string
#schema-put(5, ("a",), string())
