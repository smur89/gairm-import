# Changelog

## [1.0.0](https://github.com/smur89/gairm-import/compare/v0.13.0...v1.0.0) (2026-11-20)


### ⚠ BREAKING CHANGES

* object() and map() store required-keys only when it lists a key, as dependent-required and additional already were; read it with a default of an empty array.
* a hand-built or edited node with a field set to none, format included, now panics at the schema check; leave the field out instead. The none of object's additional argument is unchanged.
* number and integer reject a NaN or an infinite float with a type error that names it NaN, Infinity or -Infinity; they passed unless a bound was set.
* a translated pattern's expected writes the pattern as JSON does, so a control character reads as \u0001.
* a hand-built node carrying a field another kind reads, such as min-length on an array, now panics at the schema check, as does an else key on an if node (the field is otherwise).
* a date-time field rejects a Typst datetime with a type error, since a datetime has no offset and its string failed the field's own format. A date field still takes a date-only datetime. The format error's message and expected for date, date-time and time say RFC 3339 instead of ISO-8601.
* enum messages write values as JSON, so null rather than none; a union's expected names an enum member with its values; an enum's type expected names null only when it is the one value.
* lens-get, lens-put and lens-over are renamed to schema-get, schema-put and schema-update, with no aliases.
* set-required now adds keys to an object's required-keys instead of replacing them. To replace the list, use schema-update on the object and set required-keys there.
* add-field and remove-field take the field's path, ending in its name, instead of the object's path and a separate key. Where a call passed `at` and `key`, pass `at + (key,)` alone.
* `bool-type`, `null-type`, `any-type` and `content-type` are replaced by `boolean()`, `null()`, `unknown()` and `markup()`, and the kind names `bool`, `any` and `content` by `boolean`, `unknown` and `markup`.
* the lens dictionary form of a location is gone; where you passed `(lens: p)`, pass the path `p` itself.
* a `dependent` error record's `expected` is now the dependent-required entry of the key that triggered it, and its `got` is none. They were the missing key and the trigger; the missing key is still the record's path.
* a hand-built node whose bounds no value meets, or a closed object requiring a key it does not declare, now panics at the entry point naming its path, instead of rejecting every input.
* a `date` field rejects `YYYY` and `YYYY-MM`, and a `date-time` or `time` field rejects a value with no offset. Use a `pattern`, or `anyOf` with `format: "date"` as REFERENCE.md's stricter JSON Resume recipe does, to keep accepting them.
* paths-of-kind is renamed find-paths.
* validate, coerce and parse take the schema, then the data. Change `validate(data, schema: s)` to `validate(s, data)`; the old call fails with "missing argument: data".
* find-paths, formerly paths-of-kind, queried by one-of, any-of, nullable or const-of returns only the nodes that constructor builds, and a dependent error's path is the missing key rather than the object. A key that is both required and a missing dependent gets only the required error. map takes only a schema: where you wrote `map(true)`, use an object with no fields and `additional: true`.
* `resume-schema` and `resume-schema-strict` are removed. Translate your own copy of the JSON Resume schema with `schema-from-json-schema`, and build the stricter variant as REFERENCE.md's "A stricter JSON Resume" shows.
* removed, with their replacements:
    - `str-type`, `number-type`, `integer-type` → `string()`, `number()`,
      `integer()`
    - `date-string`, `datetime-string`, `uri-string`, `email-string`,
      `uuid-string`, `hostname-string`, `ipv4-string`, `ipv6-string`,
      `time-string` → `string(format: f)`, where `f` is `"date"`,
      `"date-time"`, `"uri"`, `"email"`, `"uuid"`, `"hostname"`, `"ipv4"`,
      `"ipv6"` or `"time"`
    - `pattern-string(re, expected: e)` → `string(pattern: re, expected: e)`
    - `lens(path)` → the path itself; `lens-then(a, b)` → `a + b` on the
      paths; `kind-at(schema, at)` → `schema-get(schema, at).kind`
    - the lens-first order `lens-get(at, schema)`, `lens-put(at, schema,
      v)`, `lens-over(at, schema, fn)` → `schema-get`, `schema-put`,
      `schema-update`, the schema first
    - the `(kind: "lens", path: p)` shape → the path `p`
    - a kind name string in `find-paths`, formerly paths-of-kind → a node or
      a constructor
    - hand-built `(kind: "str")`, `(kind: "pattern-string")`, `(kind:
      "date-string")` … → `(kind: "string")` with a `pattern` or `format`
      field
    - a hand-built `(kind: "number", integer: true)` → `integer()`

### Features

* accept a decimal for the number and integer bounds and multiple-of ([da8eb2e](https://github.com/smur89/gairm-import/commit/da8eb2e91cdfaacb4ff6403e19c99b93e863f6bb))
* accept a Typst decimal wherever a number is expected ([0ced0f8](https://github.com/smur89/gairm-import/commit/0ced0f8792017c498bd5a1abbe5bff26b6208af3))
* check date, date-time and time as RFC 3339, as draft 7 defines them ([0ced0f8](https://github.com/smur89/gairm-import/commit/0ced0f8792017c498bd5a1abbe5bff26b6208af3))
* give a dependent error the rule it broke as expected ([9864679](https://github.com/smur89/gairm-import/commit/9864679986b3d29aa106a697e9a6b2df6e09f9ff))
* give add-field and remove-field the field's own schema path ([eac7d08](https://github.com/smur89/gairm-import/commit/eac7d08bc55427e853109a433357722711bc75fc))
* hold a hand-built schema node to its constructor's rules ([9864679](https://github.com/smur89/gairm-import/commit/9864679986b3d29aa106a697e9a6b2df6e09f9ff))
* leave an empty required-keys out of an object node ([0c107ca](https://github.com/smur89/gairm-import/commit/0c107ca8e11a6f3c4395a91151ae17f38a4839b9))
* let enum-of take its values as separate arguments ([da8eb2e](https://github.com/smur89/gairm-import/commit/da8eb2e91cdfaacb4ff6403e19c99b93e863f6bb))
* make every schema a constructor call ([9864679](https://github.com/smur89/gairm-import/commit/9864679986b3d29aa106a697e9a6b2df6e09f9ff))
* make set-required add keys rather than replace the list ([eac7d08](https://github.com/smur89/gairm-import/commit/eac7d08bc55427e853109a433357722711bc75fc))
* narrow find-paths constructor queries and point dependent errors at the missing key ([0c55205](https://github.com/smur89/gairm-import/commit/0c552055d2b7ad567712800d5ec86277065772f4))
* quote a translated pattern as JSON in its expected text ([ea9bd77](https://github.com/smur89/gairm-import/commit/ea9bd7752afb20f95020b85c0347878d1ba16291))
* refuse a hand-built node's field that only another kind reads ([677e859](https://github.com/smur89/gairm-import/commit/677e859ef25e4c36cd06e868cbf39222063011d4))
* refuse a schema node field set to none, and say to leave it out ([ea9bd77](https://github.com/smur89/gairm-import/commit/ea9bd7752afb20f95020b85c0347878d1ba16291))
* reject NaN and infinity as numbers ([ea9bd77](https://github.com/smur89/gairm-import/commit/ea9bd7752afb20f95020b85c0347878d1ba16291))
* remove the bundled JSON Resume schemas ([3cafaa2](https://github.com/smur89/gairm-import/commit/3cafaa23a410ac64e885503a9c08ccc5fcf3e972))
* remove the deprecated constants, lens helpers and old forms ([759a291](https://github.com/smur89/gairm-import/commit/759a29164c4a651ccb51e669489307a85aaaae4b))
* rename paths-of-kind to find-paths, and ignore a pattern's expected text when matching ([eb3f39e](https://github.com/smur89/gairm-import/commit/eb3f39ef46005f0a627c7c5994affe4cdc2a92fc))
* rename the lenses to schema-get, schema-put and schema-update ([eac7d08](https://github.com/smur89/gairm-import/commit/eac7d08bc55427e853109a433357722711bc75fc))
* say where in the schema a translator panic is, and quote its values as JSON ([d44fbab](https://github.com/smur89/gairm-import/commit/d44fbab2fea59ab9ff95935f298acef6e053d9b5))
* settle the type names union, not and integer errors report ([#207](https://github.com/smur89/gairm-import/issues/207)) ([ad22fe5](https://github.com/smur89/gairm-import/commit/ad22fe58d25116e166df464c6bf548b9afd9bb5d))
* take a schema path only as an array ([9864679](https://github.com/smur89/gairm-import/commit/9864679986b3d29aa106a697e9a6b2df6e09f9ff))
* take no Typst datetime in a date-time field ([677e859](https://github.com/smur89/gairm-import/commit/677e859ef25e4c36cd06e868cbf39222063011d4))
* take the schema first in validate, coerce and parse ([0c55205](https://github.com/smur89/gairm-import/commit/0c552055d2b7ad567712800d5ec86277065772f4))
* write values as JSON in enum and union messages, and name enum members by their values ([677e859](https://github.com/smur89/gairm-import/commit/677e859ef25e4c36cd06e868cbf39222063011d4))


### Bug Fixes

* check add-field's new field as schema-put checks a node, so additional false closes it ([f84a6ed](https://github.com/smur89/gairm-import/commit/f84a6edc70f0f0ff08ab7bae1090a099cbdc3659))
* check an if's condition when it has no then or else ([d44fbab](https://github.com/smur89/gairm-import/commit/d44fbab2fea59ab9ff95935f298acef6e053d9b5))
* check the whole schema at every entry point, so a malformed node fails in the package's words ([0ced0f8](https://github.com/smur89/gairm-import/commit/0ced0f8792017c498bd5a1abbe5bff26b6208af3))
* check unique-items on an array of integers in one pass ([3105ccb](https://github.com/smur89/gairm-import/commit/3105ccb7bb0bff2c5b6621513a9cacb0490bd6fe))
* compare a decimal with a float bound exactly, and reject a hand-built string node whose pattern is null ([0ced0f8](https://github.com/smur89/gairm-import/commit/0ced0f8792017c498bd5a1abbe5bff26b6208af3))
* compare a float and a decimal as one number in enums and unique-items, and a large int with a float bound exactly ([677e859](https://github.com/smur89/gairm-import/commit/677e859ef25e4c36cd06e868cbf39222063011d4))
* compare enum and const as enum-of does, so an int past 2^53 is not the float it rounds to ([0c107ca](https://github.com/smur89/gairm-import/commit/0c107ca8e11a6f3c4395a91151ae17f38a4839b9))
* draw a schema whose field named additionalProperties shadows its additional schema ([f84a6ed](https://github.com/smur89/gairm-import/commit/f84a6edc70f0f0ff08ab7bae1090a099cbdc3659))
* draw an array of arrays on one row in describe-schema, with numbers as messages write them ([677e859](https://github.com/smur89/gairm-import/commit/677e859ef25e4c36cd06e868cbf39222063011d4))
* draw undeclared required keys and empty objects in describe-schema ([eac7d08](https://github.com/smur89/gairm-import/commit/eac7d08bc55427e853109a433357722711bc75fc))
* find a recursive $ref by its decoded target, so %61 and a are one ([ea9bd77](https://github.com/smur89/gairm-import/commit/ea9bd7752afb20f95020b85c0347878d1ba16291))
* find an open Typst Universe PR on a re-run of the release job ([0c107ca](https://github.com/smur89/gairm-import/commit/0c107ca8e11a6f3c4395a91151ae17f38a4839b9))
* harden the edges the pre-1.0 review found ([#227](https://github.com/smur89/gairm-import/issues/227)) ([3de5d30](https://github.com/smur89/gairm-import/commit/3de5d3024678e4a8913f25176ebabce4d353e44a))
* hint swapped arguments to find-paths, and give the package's own panic for an integer segment in set-required and unset-required ([3105ccb](https://github.com/smur89/gairm-import/commit/3105ccb7bb0bff2c5b6621513a9cacb0490bd6fe))
* hint the argument order in add-field and remove-field, a data path used as a schema path, and a map's value schema in remove-field ([ea9bd77](https://github.com/smur89/gairm-import/commit/ea9bd7752afb20f95020b85c0347878d1ba16291))
* hint the slips the sixth review found: a map key or properties segment in a schema path, an object edit given a field's path, a key that is only required, a schema in the path's place, and a URI fragment's # ([0c107ca](https://github.com/smur89/gairm-import/commit/0c107ca8e11a6f3c4395a91151ae17f38a4839b9))
* judge a float multiple-of exactly, as the decimal it is written as ([da8eb2e](https://github.com/smur89/gairm-import/commit/da8eb2e91cdfaacb4ff6403e19c99b93e863f6bb))
* judge a translated enum's array values with their null items ([677e859](https://github.com/smur89/gairm-import/commit/677e859ef25e4c36cd06e868cbf39222063011d4))
* keep only the enum values equal to a const beside them ([d44fbab](https://github.com/smur89/gairm-import/commit/d44fbab2fea59ab9ff95935f298acef6e053d9b5))
* know a union's null member by its kind, so an annotated one counts ([da8eb2e](https://github.com/smur89/gairm-import/commit/da8eb2e91cdfaacb4ff6403e19c99b93e863f6bb))
* lend an if branch its siblings' type only when that type is object, so the siblings are named, not the branch ([0c107ca](https://github.com/smur89/gairm-import/commit/0c107ca8e11a6f3c4395a91151ae17f38a4839b9))
* let a nullable or a conditional nest as deep as an object ([da8eb2e](https://github.com/smur89/gairm-import/commit/da8eb2e91cdfaacb4ff6403e19c99b93e863f6bb))
* let add-field and remove-field take a path ending in an int, as every schema path does ([f84a6ed](https://github.com/smur89/gairm-import/commit/f84a6edc70f0f0ff08ab7bae1090a099cbdc3659))
* let an edit through nested nullable objects reach as deep as validate, less one level ([ea9bd77](https://github.com/smur89/gairm-import/commit/ea9bd7752afb20f95020b85c0347878d1ba16291))
* let an if beside only type: "object" take closed branches ([d44fbab](https://github.com/smur89/gairm-import/commit/d44fbab2fea59ab9ff95935f298acef6e053d9b5))
* let coerce model a union value that several members claim, as the first one that leaves a model ([677e859](https://github.com/smur89/gairm-import/commit/677e859ef25e4c36cd06e868cbf39222063011d4))
* let schema-update and schema-put close an object with additional false ([677e859](https://github.com/smur89/gairm-import/commit/677e859ef25e4c36cd06e868cbf39222063011d4))
* let the object edits take a hand-built object with no required-keys ([#223](https://github.com/smur89/gairm-import/issues/223)) ([f2f3c85](https://github.com/smur89/gairm-import/commit/f2f3c85626970821ff8b87d6978b08eaedc0483d))
* let the translator read schemas nested as deep as the walk takes them ([d44fbab](https://github.com/smur89/gairm-import/commit/d44fbab2fea59ab9ff95935f298acef6e053d9b5))
* make error paths unambiguous, so a key that is not a plain name reads `["a.b"].c`, and word the remaining panics like the rest ([0ced0f8](https://github.com/smur89/gairm-import/commit/0ced0f8792017c498bd5a1abbe5bff26b6208af3))
* make unique-items fast on large arrays, align describe-schema by character, report a doubled required key once, and stop suggesting unrelated short keys ([0c55205](https://github.com/smur89/gairm-import/commit/0c552055d2b7ad567712800d5ec86277065772f4))
* name a nested union by its members in union and not messages ([da8eb2e](https://github.com/smur89/gairm-import/commit/da8eb2e91cdfaacb4ff6403e19c99b93e863f6bb))
* name an if branch that is no object schema as written, not by its siblings' keywords ([f84a6ed](https://github.com/smur89/gairm-import/commit/f84a6edc70f0f0ff08ab7bae1090a099cbdc3659))
* name an untyped allOf member by what it lacks, not as a union ([d44fbab](https://github.com/smur89/gairm-import/commit/d44fbab2fea59ab9ff95935f298acef6e053d9b5))
* name constructors in find-paths' query panic ([eac7d08](https://github.com/smur89/gairm-import/commit/eac7d08bc55427e853109a433357722711bc75fc))
* name the value, not its type, when coerce misses an enum ([da8eb2e](https://github.com/smur89/gairm-import/commit/da8eb2e91cdfaacb4ff6403e19c99b93e863f6bb))
* panic on an embedded $id, and read a null-first nullable and an additionalProperties $ref to {} in allOf ([677e859](https://github.com/smur89/gairm-import/commit/677e859ef25e4c36cd06e868cbf39222063011d4))
* panic with the package's own message on bad arguments to the constructors, lenses, introspection, pointers and run functions, and refuse integer bounds that leave no whole number ([0c55205](https://github.com/smur89/gairm-import/commit/0c552055d2b7ad567712800d5ec86277065772f4))
* point at member 0 when a schema path misses a nullable's schema ([eac7d08](https://github.com/smur89/gairm-import/commit/eac7d08bc55427e853109a433357722711bc75fc))
* read $ref "#/" as a JSON Pointer to the key "", and skip a shadowed additional schema in find-paths ([0c55205](https://github.com/smur89/gairm-import/commit/0c552055d2b7ad567712800d5ec86277065772f4))
* read a stored pattern only as a regex, coerce a union as its sole claimant, and report a NaN against a bound ([#222](https://github.com/smur89/gairm-import/issues/222)) ([1446dce](https://github.com/smur89/gairm-import/commit/1446dce9a0de582b51ae990d4ece3dc3864f607f))
* read additionalProperties {} as true ([d44fbab](https://github.com/smur89/gairm-import/commit/d44fbab2fea59ab9ff95935f298acef6e053d9b5))
* read the objects under not as open, as draft 7 does ([d44fbab](https://github.com/smur89/gairm-import/commit/d44fbab2fea59ab9ff95935f298acef6e053d9b5))
* read type ["object"] beside if as type "object" ([f84a6ed](https://github.com/smur89/gairm-import/commit/f84a6edc70f0f0ff08ab7bae1090a099cbdc3659))
* refuse a pattern or format on a hand-built markup node ([da8eb2e](https://github.com/smur89/gairm-import/commit/da8eb2e91cdfaacb4ff6403e19c99b93e863f6bb))
* reject a date or date-time whose day its month lacks, such as 2023-02-29 ([f84a6ed](https://github.com/smur89/gairm-import/commit/f84a6edc70f0f0ff08ab7bae1090a099cbdc3659))
* reject a hand-built conditional with neither branch at the schema check ([da8eb2e](https://github.com/smur89/gairm-import/commit/da8eb2e91cdfaacb4ff6403e19c99b93e863f6bb))
* report a key a hand-built object lists twice once ([da8eb2e](https://github.com/smur89/gairm-import/commit/da8eb2e91cdfaacb4ff6403e19c99b93e863f6bb))
* report a string's length errors beside its pattern or format miss ([677e859](https://github.com/smur89/gairm-import/commit/677e859ef25e4c36cd06e868cbf39222063011d4))
* report a string's pattern miss beside its format miss ([f84a6ed](https://github.com/smur89/gairm-import/commit/f84a6edc70f0f0ff08ab7bae1090a099cbdc3659))
* say how to set an object's additional schema or an if-of branch that a schema path names but the node lacks ([3105ccb](https://github.com/smur89/gairm-import/commit/3105ccb7bb0bff2c5b6621513a9cacb0490bd6fe))
* say JSON text from read() needs encoding: none, instead of calling it a string path ([0c107ca](https://github.com/smur89/gairm-import/commit/0c107ca8e11a6f3c4395a91151ae17f38a4839b9))
* say that draft 4's boolean exclusiveMinimum and exclusiveMaximum are not supported ([d44fbab](https://github.com/smur89/gairm-import/commit/d44fbab2fea59ab9ff95935f298acef6e053d9b5))
* see through a nullable anyOf when merging closed objects ([d44fbab](https://github.com/smur89/gairm-import/commit/d44fbab2fea59ab9ff95935f298acef6e053d9b5))
* skip the "Did you mean" suggestion past ten unknown keys, and list an object's valid keys once, so a large map-shaped document validates quickly against an object ([3105ccb](https://github.com/smur89/gairm-import/commit/3105ccb7bb0bff2c5b6621513a9cacb0490bd6fe))
* step a numeric field name through a schema path, and hint a JSON Schema document or an uncalled constructor passed as a schema ([677e859](https://github.com/smur89/gairm-import/commit/677e859ef25e4c36cd06e868cbf39222063011d4))
* store a pattern's expected only when given, and check a find-paths query before reading it ([#221](https://github.com/smur89/gairm-import/issues/221)) ([504a27e](https://github.com/smur89/gairm-import/commit/504a27e4a0329ad6a0caba99fe7275cbe740a455))
* suggest a rewrite that keeps their meaning for keywords beside not or $ref, and name a $ref to an anchor as one ([3105ccb](https://github.com/smur89/gairm-import/commit/3105ccb7bb0bff2c5b6621513a9cacb0490bd6fe))
* tell an int past 2^53 from the float it rounds to in enum membership ([f84a6ed](https://github.com/smur89/gairm-import/commit/f84a6edc70f0f0ff08ab7bae1090a099cbdc3659))
* translate an if beside an additionalProperties schema once per level, not once per branch ([3105ccb](https://github.com/smur89/gairm-import/commit/3105ccb7bb0bff2c5b6621513a9cacb0490bd6fe))
* translate an if beside sibling properties without translating them again in each branch ([ea9bd77](https://github.com/smur89/gairm-import/commit/ea9bd7752afb20f95020b85c0347878d1ba16291))
* translate schemas nested 34 levels deep, and word a required key outside properties in the translator's terms ([a13a184](https://github.com/smur89/gairm-import/commit/a13a184538685b933dafd417e7033b4f8a5a0cb5))
* translate type ["object", "null"] beside an if with both branches, and let a null through a branch that takes its type from the siblings ([0c107ca](https://github.com/smur89/gairm-import/commit/0c107ca8e11a6f3c4395a91151ae17f38a4839b9))
* treat an empty $id as no embedded $id ([f84a6ed](https://github.com/smur89/gairm-import/commit/f84a6edc70f0f0ff08ab7bae1090a099cbdc3659))
* word a hand-built node's none field, bare expected and out-of-range datetime year in field terms ([0c107ca](https://github.com/smur89/gairm-import/commit/0c107ca8e11a6f3c4395a91151ae17f38a4839b9))
* word the nullable, not-of and string pattern panics like the rest ([da8eb2e](https://github.com/smur89/gairm-import/commit/da8eb2e91cdfaacb4ff6403e19c99b93e863f6bb))
* word the translator's panics for a const outside its enum, a schema-valued dependentRequired, a boolean dependencies entry, a document that is no object, and an anyOf, not, if or type list as an allOf or if member ([ea9bd77](https://github.com/smur89/gairm-import/commit/ea9bd7752afb20f95020b85c0347878d1ba16291))

## [0.13.0](https://github.com/smur89/gairm-import/compare/v0.12.0...v0.13.0) (2026-11-12)


### Features

* deprecate the bundled JSON Resume schemas and the schema: default ([#205](https://github.com/smur89/gairm-import/issues/205)) ([11a3dcf](https://github.com/smur89/gairm-import/commit/11a3dcfb6222e73031e3bc415e112a30f4207ec7))

## [0.12.0](https://github.com/smur89/gairm-import/compare/v0.11.0...v0.12.0) (2026-11-06)


### Features

* support if / then / else conditional schemas ([#201](https://github.com/smur89/gairm-import/issues/201)) ([c8383b7](https://github.com/smur89/gairm-import/commit/c8383b7c5c482df29f375680a5b5b5a642dee3ec))

## [0.11.0](https://github.com/smur89/gairm-import/compare/v0.10.1...v0.11.0) (2026-11-06)


### Features

* accept a datetime for date-string and datetime-string ([#144](https://github.com/smur89/gairm-import/issues/144)) ([b5670d1](https://github.com/smur89/gairm-import/commit/b5670d145ec2fec42dfa9e6cbf470e49ece5495c)), closes [#134](https://github.com/smur89/gairm-import/issues/134)
* accept bytes in parse and schema-from-json-schema ([#143](https://github.com/smur89/gairm-import/issues/143)) ([23a0af7](https://github.com/smur89/gairm-import/commit/23a0af7d7b89a967c33ef949ea52a8ca633ce6f3)), closes [#133](https://github.com/smur89/gairm-import/issues/133)
* accept union members as separate arguments ([12e8047](https://github.com/smur89/gairm-import/commit/12e804753f82749cbd7bacba8dac2b27828bdbab))
* add a code, expected and got to every validation error ([#177](https://github.com/smur89/gairm-import/issues/177)) ([39365f2](https://github.com/smur89/gairm-import/commit/39365f28b2f87790edc9e51e5bd6373c577f17ab))
* add required: to add-field ([12e8047](https://github.com/smur89/gairm-import/commit/12e804753f82749cbd7bacba8dac2b27828bdbab))
* compose format and pattern on a string schema ([#151](https://github.com/smur89/gairm-import/issues/151)) ([976c24c](https://github.com/smur89/gairm-import/commit/976c24cc1ea33ac72cc870e8f800dc639f231d4b)), closes [#115](https://github.com/smur89/gairm-import/issues/115)
* deprecate passing paths-of-kind a kind name string; pass the kind value (e.g. date-string) instead, as the string form goes in the next major ([39379bb](https://github.com/smur89/gairm-import/commit/39379bbf631413ae324e8ef46948203c0f1aae23))
* deprecate str-type, number-type, integer-type, pattern-string, the format constants, lens, lens-then and kind-at in favour of the constructors and paths ([12e8047](https://github.com/smur89/gairm-import/commit/12e804753f82749cbd7bacba8dac2b27828bdbab))
* fold constraint keywords into enum / const membership ([#152](https://github.com/smur89/gairm-import/issues/152)) ([a8534e3](https://github.com/smur89/gairm-import/commit/a8534e3d47054d3481b9fd699caa0da4ac4376d1)), closes [#111](https://github.com/smur89/gairm-import/issues/111)
* let lenses and introspection reach into unions and not ([#181](https://github.com/smur89/gairm-import/issues/181)) ([45ae3f6](https://github.com/smur89/gairm-import/commit/45ae3f684bffc85c08bd3146ec7340a7df750a0c)), closes [#164](https://github.com/smur89/gairm-import/issues/164)
* let parse take any root the schema accepts, and share one input rule ([12e8047](https://github.com/smur89/gairm-import/commit/12e804753f82749cbd7bacba8dac2b27828bdbab))
* make a string's format a field instead of a kind ([#195](https://github.com/smur89/gairm-import/issues/195)) ([4fd09b9](https://github.com/smur89/gairm-import/commit/4fd09b95c3365261e85a313e1f054ad7bea51994))
* name the string kind "string", keeping "str" as an alias ([12e8047](https://github.com/smur89/gairm-import/commit/12e804753f82749cbd7bacba8dac2b27828bdbab))
* put the schema first and let a path stand in for a lens ([#188](https://github.com/smur89/gairm-import/issues/188)) ([0e012ca](https://github.com/smur89/gairm-import/commit/0e012ca3914c7b98150167d62f517462d8a452d5)), closes [#163](https://github.com/smur89/gairm-import/issues/163)
* support dependentRequired and array-form dependencies ([e396993](https://github.com/smur89/gairm-import/commit/e396993601fda4187e7f179ac3ecc45140c357d0))
* support uuid, hostname, ipv4, ipv6 and time string formats ([e396993](https://github.com/smur89/gairm-import/commit/e396993601fda4187e7f179ac3ecc45140c357d0))
* take Typst values where an API took a name in a string ([39379bb](https://github.com/smur89/gairm-import/commit/39379bbf631413ae324e8ef46948203c0f1aae23))
* translate JSON Schema nodes with no type ([#184](https://github.com/smur89/gairm-import/issues/184)) ([66516af](https://github.com/smur89/gairm-import/commit/66516afa5441aa8facae26dd4798593f1f5d7b6c))
* translate type arrays with several non-null members to any-of ([#153](https://github.com/smur89/gairm-import/issues/153)) ([f2bec53](https://github.com/smur89/gairm-import/commit/f2bec53e6190ae3dfb249a243259ed87f662b779)), closes [#112](https://github.com/smur89/gairm-import/issues/112)


### Bug Fixes

* assert no iso8601 leaf is left unlisted in the strict schema ([#158](https://github.com/smur89/gairm-import/issues/158)) ([b1dd488](https://github.com/smur89/gairm-import/commit/b1dd4887bc87d0f4750de6b2e3e3b58906c277e9))
* bail on malformed or null JSON Schema keyword values ([#190](https://github.com/smur89/gairm-import/issues/190)) ([91210e0](https://github.com/smur89/gairm-import/commit/91210e0b7e774a1a553bb0a7638f618edcbc4ede))
* bail on non-annotation siblings of $ref ([#150](https://github.com/smur89/gairm-import/issues/150)) ([28eaf3e](https://github.com/smur89/gairm-import/commit/28eaf3e9f9c647095183968ce5e907cb1e195c5e)), closes [#118](https://github.com/smur89/gairm-import/issues/118)
* four translator and format bugs found by the JSON Schema test suite ([#183](https://github.com/smur89/gairm-import/issues/183)) ([4b26154](https://github.com/smur89/gairm-import/commit/4b26154877c51e9fa648aaf0cddca84752180d98))
* keep a JSON Pointer index too large for an int as a string ([c833a02](https://github.com/smur89/gairm-import/commit/c833a02b86ef5ec41c844c05ee68925484d93615))
* keep object() invariants through lens edits and check incoming schemas ([#185](https://github.com/smur89/gairm-import/issues/185)) ([ca787d2](https://github.com/smur89/gairm-import/commit/ca787d2d9d5de1fe3c99e1c096b3b51b1c6b4fed))
* make the translator bail instead of dropping or misreading keywords ([#159](https://github.com/smur89/gairm-import/issues/159)) ([caf81bd](https://github.com/smur89/gairm-import/commit/caf81bd7816516e8dc7d2a3b99cabd2f0442eca0))
* make validate and coerce agree, and harden the union and number checks ([#160](https://github.com/smur89/gairm-import/issues/160)) ([2971147](https://github.com/smur89/gairm-import/commit/297114770a1b371cf0f08eae01e78ea198a2aee0))
* name tuple-form items in its panic instead of blaming boolean schemas ([b0b26cb](https://github.com/smur89/gairm-import/commit/b0b26cbfa224ad2997255729a55220026a7825c6))
* reject a string path in parse; it resolved from the package root, so pass path("…") instead ([eca2b9c](https://github.com/smur89/gairm-import/commit/eca2b9cfa6dbafb65c0a350f4c5d14bb864a631f))
* report a null JSON Schema as a schema problem, not a document one ([b0b26cb](https://github.com/smur89/gairm-import/commit/b0b26cbfa224ad2997255729a55220026a7825c6))
* report errors with panic, and test that each panic fires ([83ed33f](https://github.com/smur89/gairm-import/commit/83ed33f983b9f3d2fb011702c66576677e343569))
* route lens object edits through object(), so they keep its invariants ([ca787d2](https://github.com/smur89/gairm-import/commit/ca787d2d9d5de1fe3c99e1c096b3b51b1c6b4fed)), closes [#165](https://github.com/smur89/gairm-import/issues/165)
* stop calling the input root a dict in the null-input panic ([b0b26cb](https://github.com/smur89/gairm-import/commit/b0b26cbfa224ad2997255729a55220026a7825c6))

## [0.10.1](https://github.com/smur89/gairm-import/compare/v0.10.0...v0.10.1) (2026-11-02)


### Bug Fixes

* point the README render example at altacv 1.7.0 ([#130](https://github.com/smur89/gairm-import/issues/130)) ([5b92dad](https://github.com/smur89/gairm-import/commit/5b92dad5be42de516a9a6ec12254f2b0484afe49))

## [0.10.0](https://github.com/smur89/gairm-import/compare/v0.9.0...v0.10.0) (2026-11-02)


### Features

* update vendored JSON Resume schema to 1.7.0 ([#127](https://github.com/smur89/gairm-import/issues/127)) ([18e91d7](https://github.com/smur89/gairm-import/commit/18e91d74cf440190d80dd92e3f4c774fb9633aaa))


### Bug Fixes

* accept the spec datetime for strict meta.lastModified ([#128](https://github.com/smur89/gairm-import/issues/128)) ([7af57a5](https://github.com/smur89/gairm-import/commit/7af57a56910b800083f77fe5859e2171d70dadee))

## [0.9.0](https://github.com/smur89/gairm-import/compare/v0.8.1...v0.9.0) (2026-07-12)


### Features

* enforce integral values for JSON Schema type "integer" ([#103](https://github.com/smur89/gairm-import/issues/103)) ([ce1610a](https://github.com/smur89/gairm-import/commit/ce1610aaa11e44b1f350f2e8a149b216940e25f6))
* JSON Schema composition keywords — allOf, anyOf, oneOf, not ([#117](https://github.com/smur89/gairm-import/issues/117)) ([2841e16](https://github.com/smur89/gairm-import/commit/2841e1625ac89e14c365bd825da737280279d1ba))

## [0.8.1](https://github.com/smur89/gairm-import/compare/v0.8.0...v0.8.1) (2026-06-17)


### Bug Fixes

* align rendering forward-link with the section it points to ([#94](https://github.com/smur89/gairm-import/issues/94)) ([d53f366](https://github.com/smur89/gairm-import/commit/d53f3665b6020fd5ccffc50de2739478461e98d6))

## [0.8.0](https://github.com/smur89/gairm-import/compare/v0.7.0...v0.8.0) (2026-06-17)


### Features

* JSON Schema constraint keywords ([#85](https://github.com/smur89/gairm-import/issues/85)) ([f2b301a](https://github.com/smur89/gairm-import/commit/f2b301a9e14d473203af3b9f61bcc2a1e5c5eccf))
* type coverage for boolean, null, and [X, "null"] unions ([#83](https://github.com/smur89/gairm-import/issues/83)) ([3081e24](https://github.com/smur89/gairm-import/commit/3081e24123268d2714f4f6b7ec9b9b8ea3633941))

## [0.7.0](https://github.com/smur89/gairm-import/compare/v0.6.0...v0.7.0) (2026-06-16)


### Features

* schema introspection helpers (describe-schema, paths-of-kind, kind-at) ([#54](https://github.com/smur89/gairm-import/issues/54)) ([d72b282](https://github.com/smur89/gairm-import/commit/d72b282268d882ad90b3a10dac9cc7e703a5cfd3))

## [0.6.0](https://github.com/smur89/gairm-import/compare/v0.5.1...v0.6.0) (2026-06-16)


### Features

* datetime-string kind for format: date-time fields ([#55](https://github.com/smur89/gairm-import/issues/55)) ([bfa6ce5](https://github.com/smur89/gairm-import/commit/bfa6ce5ce90cc3bf984a376dad84a95260b3f4dc))
* pattern-string kind for JSON Schema pattern keyword ([#53](https://github.com/smur89/gairm-import/issues/53)) ([19e8809](https://github.com/smur89/gairm-import/commit/19e88090d77c30ee8fd41be7b7b8a1acee50846c))
* suggest closest matching key in unknown-key error messages ([#19](https://github.com/smur89/gairm-import/issues/19)) ([9769de5](https://github.com/smur89/gairm-import/commit/9769de5f83d177ce03e27319b59b6df14d1b38a9))

## [0.5.1](https://github.com/smur89/gairm-import/compare/v0.5.0...v0.5.1) (2026-06-16)


### Bug Fixes

* hide release-please version markers from rendered README ([#57](https://github.com/smur89/gairm-import/issues/57)) ([0f33b09](https://github.com/smur89/gairm-import/commit/0f33b09b5acf2f806a429d694094589ab6e5d41b))

## [0.5.0](https://github.com/smur89/typst-json-resume/compare/v0.4.0...v0.5.0) (2026-06-15)


### Features

* set-required lens companion for editing object required-keys ([#48](https://github.com/smur89/typst-json-resume/issues/48)) ([7dc58b1](https://github.com/smur89/typst-json-resume/commit/7dc58b14a578f822bd7c4d3be37022ac92b0afa9))

## [0.4.0](https://github.com/smur89/typst-json-resume/compare/v0.3.0...v0.4.0) (2026-06-15)


### Features

* translator + validator support for JSON Schema enum and const ([#46](https://github.com/smur89/typst-json-resume/issues/46)) ([8e6e2d8](https://github.com/smur89/typst-json-resume/commit/8e6e2d84e22fea652374edcc88ee61f3539d2068))

## [0.3.0](https://github.com/smur89/typst-json-resume/compare/v0.2.0...v0.3.0) (2026-06-15)


### Features

* split resume-schema into faithful default + opt-in strict variant ([#35](https://github.com/smur89/typst-json-resume/issues/35)) ([908d628](https://github.com/smur89/typst-json-resume/commit/908d62888201a7203a8226f6c2a5ace081a4dca2))

## [0.2.0](https://github.com/smur89/typst-json-resume/compare/v0.1.1...v0.2.0) (2026-06-15)


### Features

* derive resume-schema from vendored JSON Schema document ([#33](https://github.com/smur89/typst-json-resume/issues/33)) ([7f01328](https://github.com/smur89/typst-json-resume/commit/7f013281c2ee5aed5eb9a3ddb9d3694039a28720))
* expose validate / coerce engines and schema combinators publicly ([#17](https://github.com/smur89/typst-json-resume/issues/17)) ([a37b8e0](https://github.com/smur89/typst-json-resume/commit/a37b8e0279d64f139eae32f3b3d8fb636673c5ce))
* lens-style schema editing for JSON-Resume+ extensions ([#30](https://github.com/smur89/typst-json-resume/issues/30)) ([33aee49](https://github.com/smur89/typst-json-resume/commit/33aee49a910fe207a40c79092ea997714478e605))
* schema-from-json-schema — translate a JSON Schema document into a Typst schema ([#24](https://github.com/smur89/typst-json-resume/issues/24)) ([7f16ce9](https://github.com/smur89/typst-json-resume/commit/7f16ce9695a03acb9b803fd39bc11eaabb046df5))
* treat JSON null as if the key were absent ([#20](https://github.com/smur89/typst-json-resume/issues/20)) ([e9e8cbe](https://github.com/smur89/typst-json-resume/commit/e9e8cbe66a6e1931b738d6089ec1f66a1d73dcf3))

## [0.1.1](https://github.com/smur89/typst-json-resume/compare/v0.1.0...v0.1.1) (2026-06-15)


### Bug Fixes

* **release:** clear typst/packages submission errors and warnings ([#13](https://github.com/smur89/typst-json-resume/issues/13)) ([fc9c512](https://github.com/smur89/typst-json-resume/commit/fc9c5124911d088a86cf588771aae451b91a364d))

## [0.1.0](https://github.com/smur89/typst-json-resume/compare/v0.0.1...v0.1.0) (2026-06-14)


### Features

* implement v0.1 of the JSON Resume loader ([#7](https://github.com/smur89/typst-json-resume/issues/7)) ([7b5be34](https://github.com/smur89/typst-json-resume/commit/7b5be34746b0e9b84e5c9273a833df96d7b7c0f7))
* scaffold the json-resume package ([adf5b63](https://github.com/smur89/typst-json-resume/commit/adf5b6329231c9e51079ebd737c928e2e283a87e))

## Changelog
