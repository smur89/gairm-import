// expect: Valid keys: none. To drop the additional schema, use schema-update on the object: o => (..o, additional: none).
#import "../../lib.typ": remove-field, map, string
#remove-field(map(string()), ("additionalProperties",))
