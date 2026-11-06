// expect: "then" has no effect without "if" (draft 7 ignores it), so translating would silently drop its constraints.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((type: "string", then: (minLength: 2)))
