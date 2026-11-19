// expect: coerce at d: expected a string or a datetime with a date in years 0 to 9999 and no time, got datetime.
#import "../../lib.typ": coerce, object, string
#coerce(
  object((
    d: string(format: "date"),
  )),
  (d: datetime(hour: 9, minute: 0, second: 0)),
)
