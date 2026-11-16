// expect: validate does not take a string path
#import "../../lib.typ": validate, object
#validate("/tests/fixtures/resume-minimal.json", schema: object((:)))
