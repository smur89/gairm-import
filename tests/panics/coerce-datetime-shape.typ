// expect: coerce expected a string or a datetime with a date and no time, got datetime.
#import "../../lib.typ": coerce, object, date-string
#coerce((d: datetime(hour: 9, minute: 0, second: 0)), schema: object((
  d: date-string,
)))
