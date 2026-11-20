// expect: needs the object's `additional` to be a schema, got: none. To set one, schema-update the object: o => (..o, additional: value).
#import "../../lib.typ": schema-put, object, string
#schema-put(
  object((a: object((b: string())))),
  ("a", "additionalProperties"),
  string(),
)
