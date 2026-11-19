// expect: schema-put path must be an array of path segments, got: a schema. The path comes before the schema to write.
#import "/lib.typ": schema-put, object, string, number
#schema-put(object((a: string())), number(), ("a",))
