// expect: pointer-to-path pointer must be "" or a pointer starting with "/", got: "#/a". Drop the "#" a URI fragment starts with.
#import "/lib.typ": pointer-to-path
#pointer-to-path("#/a")
