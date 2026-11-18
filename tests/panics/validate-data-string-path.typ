// expect: validate does not take a string path
#import "../../lib.typ": validate, object
#validate(object((:)), "/tests/fixtures/resume-minimal.json")
