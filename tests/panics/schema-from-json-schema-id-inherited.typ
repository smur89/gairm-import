// expect: an embedded "$id" ("other.json", at /definitions/bundle) is not supported
// A $ref to a node below an embedded $id inherits its base, so it is
// refused as one to the node carrying it is.
#import "../../lib.typ": schema-from-json-schema
#schema-from-json-schema((
  definitions: (
    value: (type: "number"),
    bundle: (
      "$id": "other.json",
      definitions: (
        value: (type: "string"),
        alias: ("$ref": "#/definitions/value"),
      ),
    ),
  ),
  "$ref": "#/definitions/bundle/definitions/alias",
))
