// expect: gairm-import: coerce at user.name: expected a string, got integer.
#import "../../lib.typ": coerce, object, any-of, number, string
// The union's sole claimant (the object) fails at a nested field:
// coerce reports that field, as validate does, not the union.
#coerce((user: (name: 1)), schema: object((
  user: any-of((object((name: string())), number())),
)))
