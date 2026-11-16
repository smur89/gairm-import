// expect: coerce at d: expected a string or a datetime with a date and no time, got datetime.
#import "../../lib.typ": coerce, object, string
#coerce((d: datetime(hour: 9, minute: 0, second: 0)), schema: object((
  d: string(format: "date"),
)))
