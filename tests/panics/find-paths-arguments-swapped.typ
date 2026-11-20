// expect: find-paths takes the schema first, then the query: find-paths(schema, query).
#import "../../lib.typ": find-paths, object, string
#find-paths(string, object((a: string())))
