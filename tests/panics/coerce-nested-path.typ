// expect: gairm-import: coerce at work[0].name: expected a string, got integer. Run validate(data) first.
#import "../../lib.typ": array-of, coerce, object, str-type
#coerce(
  (work: ((name: 1),)),
  schema: object((work: array-of(object((name: str-type))))),
)
