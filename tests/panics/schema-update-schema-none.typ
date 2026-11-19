// expect: schema-update takes a schema, then a path (an array of segments); got none and none.
#import "../../lib.typ": schema-update
#schema-update(none, none, s => s)
