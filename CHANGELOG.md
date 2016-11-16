<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Changelog](#changelog)
  - [v3.0.0](#v300)
    - [Enhancements](#enhancements)
    - [Bug Fixes](#bug-fixes)
    - [Incompatible Changes](#incompatible-changes)
  - [v2.4.0](#v240)
    - [Enhancements](#enhancements-1)
  - [v2.3.0](#v230)
    - [Enhancements](#enhancements-2)
    - [Bug Fixes](#bug-fixes-1)
  - [v2.2.0](#v220)
    - [Enhancements](#enhancements-3)
  - [v2.1.1](#v211)
    - [Bug Fixes](#bug-fixes-2)
  - [v2.1.0](#v210)
    - [Enhancements](#enhancements-4)
    - [Bug Fixes](#bug-fixes-3)
  - [v2.0.1](#v201)
    - [Bug Fixes](#bug-fixes-4)
  - [v2.0.0](#v200)
    - [Enhancements](#enhancements-5)
    - [Bug Fixes](#bug-fixes-5)
    - [Incompatible Changes](#incompatible-changes-1)
  - [v1.0.0](#v100)
    - [Enhancements](#enhancements-6)
    - [Incompatible Changes](#incompatible-changes-2)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Changelog

## v3.0.0

### Enhancements

* [#39](https://github.com/C-S-D/alembic/pull/39) - [KronicDeth](https://github.com/KronicDeth)
  * Update dependencies
    * `credo` to `0.5.2`
    * `ex_doc` to `0.14.3`
    * `inch_ex` to `0.5.5`
    * `junit_formatter` to `1.1.0`
  * Build with Erlang 19.1 and Elixir 1.3.4 on CircleCI.
 
### Bug Fixes
* [#39](https://github.com/C-S-D/alembic/pull/39) - [KronicDeth](https://github.com/KronicDeth)
  * Ecto 2.1 makes the warning about `cast/4` instead of `cast/3` noisy, but Ecto 1.X had the opposite warning to use `cast/4` instead of `cast/3`, so use `cast/3`.
  * Fix all Erlang 19.1 dialyzer warnings.
  
### Incompatible Changes
* [#39](https://github.com/C-S-D/alembic/pull/39) - Drop Ecto 1.0 since Ecto 1.0's `cast/3` is different than Ecto 2.0's `cast/3.` - [KronicDeth](https://github.com/KronicDeth)

## v2.4.0

### Enhancements
* [#38](https://github.com/C-S-D/alembic/pull/38) - CodeClimate just added credo support to their beta engines channel.  Running on CodeClimate will allow the credo tests to run in parallel with CircleCI, leading to faster overall build times. - [KronicDeth](https://github.com/KronicDeth)

## v2.3.0

### Enhancements
* [#32](https://github.com/C-S-D/alembic/pull/32) - `Alembic.Pagination.to_links/2` allows converting `Alembic.Pagination.t` from `Alembic.Links.to_pagination` back to `Alembic.Links.t` with urls. - [KronicDeth](https://github.com/KronicDeth)
* [#33](https://github.com/C-S-D/alembic/pull/33) - [KronicDeth](https://github.com/KronicDeth)
  * Update `coverex` to `1.4.10`
  * Update `credo` to `0.4.11`
  * Update `ecto` to `2.0.5`
  * Update `hackney` to `1.6.1`
  * Update `httpoison` to `0.9.1`
  * Update `inch_ex` to `0.5.4` 
  * Update `junit_formatter` to `1.1.0`
    * JUnit output location changed from `_build/test/test-junit-report.xml` to `_build/test/lib/alembic/test-junit-report.xml`

### Bug Fixes
* [#32](https://github.com/C-S-D/alembic/pull/32) - Fix `alias` that wasn't renamed - [KronicDeth](https://github.com/KronicDeth)

## v2.2.0

### Enhancements
* [#31](https://github.com/C-S-D/alembic/pull/30) - [KronicDeth](https://github.com/KronicDeth)
  - Update `ex_doc` to `0.12.0`
  - Update `credo` to `0.4.5`
  - Update `ecto` to `2.0.2`.  Compatibility range is changed from `~> 1.1` to `~> 1.1 or ~> 2.0`, so no incompatibility is introduced for runtime dependencies.
  
## v2.1.1

### Bug Fixes
* [#30](https://github.com/C-S-D/alembic/pull/30) - Elixir 1.3.0 compatibility - [KronicDeth](https://github.com/KronicDeth)
  - Work-around [elixir-lang/elixir#4874)](https://github.com/elixir-lang/elixir/issues/4874) by aliasing `Alembic.Source` and using `Source.t` instead of `@for.t`.
  - Use Erlang 18.3 instead of Erlang 19.0 until dialyer bug (http://bugs.erlang.org/browse/ERL-177) is fixed.

## v2.1.0

### Enhancements
* [#27](https://github.com/C-S-D/alembic/pull/25) - Add more doctests to Alembic.ToParams.nested_to_foreign_keys - [KronicDeth](https://github.com/KronicDeth)
  * `nil` for the nested parameters converts to a `nil` foreign key parameter
  * When the nested parameters are not even present, the foreign key won't be added
  *` has_many` nested params are unchanged

### Bug Fixes
* [#27](https://github.com/C-S-D/alembic/pull/25) - Convert `nil` nested params to `nil` foreign key - [KronicDeth](https://github.com/KronicDeth)

## v2.0.1

### Bug Fixes
* [#25](https://github.com/C-S-D/alembic/pull/25) - Documentation formatting - [KronicDeth](https://github.com/KronicDeth)
  * Wrong number of spaces and missing closing backquotes led to some doctests not being rendered correctly.
  * Fix docs for FromJson.from_json callback
    * Use `<name> :: <type>` format for parameters, so they don't appear as
  `arg0` and `arg1` in the generated docs.
    * Use those names in the Paramaters section and code block teh format of
    the error template.

## v2.0.0

### Enhancements
* [#10](https://github.com/C-S-D/alembic/pull/10) - `ToEctoSchema` and `ToParams` - [KronicDeth](https://github.com/KronicDeth)
  * `Alembic.Document.to_params/1` takes an `Alembic.Document.t` and converts it to the params format used by `Ecto.Changset.cast/4`
  * `Alembic.Document.to_ecto_schema/2` takes an `Alembic.Document.t` and converts it to `Ecto.Schema` structs that an be used in the rest of an application.
* [#11](https://github.com/C-S-D/alembic/pull/11) - Parse include params - [KronicDeth](https://github.com/KronicDeth)
  * `Alembic.Fetch.from_params` can extract and normalize params for controlling JSON API fetching into an `%Alembic.Fetch{}`.
  * `Alembic.Fetch.Includes.to_preloads` can convert the normalized includes to a list of preloads for `Ecto.Repo.preload` or `Ecto.Query.preload`.
  * `Alembic.Fetch.to_query` will add the preloads for `%Alembic.Fetch{}` includes to a query.
* [#12](https://github.com/C-S-D/alembic/pull/12) - Fetch.Include.preload and preload_by_include types - [KronicDeth](https://github.com/KronicDeth)
  * Use `Fetch.Include.preload` and `preload_by_include types` types instead of generic `term` and `map`.
* [#14](https://github.com/C-S-D/alembic/pull/14) - Allow `jsonapi` field in `Document.t`, so that jsonapi can be set to `%{ "version" => "1.0" }` to match `JaSerializer` output. - [KronicDeth](https://github.com/KronicDeth)
* [#15](https://github.com/C-S-D/alembic/pull/15) - `ToParams.nest_to_foreign_keys/2` converts nested parameters for `belongs_to` associations to a foreign key parameter. - [KronicDeth](https://github.com/KronicDeth)
* [#16](https://github.com/C-S-D/alembic/pull/16) - Check for "Closing unclosed backquotes" from `mix docs` on CircleCI  - [KronicDeth](https://github.com/KronicDeth)
* [#17](https://github.com/C-S-D/alembic/pull/17) - Pagination - [KronicDeth](https://github.com/KronicDeth)
  * `Pagination.Page` can store the `page[number]` and `page[size]` from a `URI`.
  * `Link.to_page` can convert a URL to an `Pagination.Page`
  * `Pagination` can store the `first`, `last`, `next`, and `previous` `Pagination.Page`s
  * `Document.to_pagination` will extract the `first`, `last`, and `next`, and `previous` `Pagination.Page` from the `"first"`, `"last"`, `"next"`, and `"prev"` top-level `links`.  The `total_size` will be extracted from the top-level `meta` `"record_count"`.  This gives compatibility with the paged paginator in `JSONAPI::Resources` with `config.top_level_meta_include_record_count = true`.
* [#18](https://github.com/C-S-D/alembic/pull/18) - Document.error_status_consensus - [KronicDeth](https://github.com/KronicDeth)
  * `Document.error_status_consensus(document :: Document.t) :: String.t` returns the consensus `Error.t` `status` for all the `errors` in the `document`.  If there are no errors or statuses, then it is `nil`; otherwise, the consensus is the status shared between all (non-`nil`) errors or the max 100s status.  For example, `"404"` and `"422"` would have a consensus of `"400"` because `400` covers both errors.  For `"404"` and `"500"` the consensus would be `"500"` because `"500"` is more serious than any 4XX error.  
* [#20](https://github.com/C-S-D/alembic/pull/20) - Indirect relationships - [KronicDeth](https://github.com/KronicDeth)
  * `ToEctoSchema.to_ecto_schema(params, module)` recursively converts nested params to the associated structs
  * `Fetch.Includes.to_string` will take a list of includes and convert it back to the common-separated string format used by JSONAPI query parameters.
* [#23](https://github.com/C-S-D/alembic/pull/23) - Allow Poison ~> 1.5 or ~> 2.0 - [KronicDeth](https://github.com/KronicDeth)
  * Allow compatibility with projects that haven't upgraded to Poison 2.0. Nothing in the `Poison.Encoder` implementations is 2.0 specific, so allow both major versions.  

### Bug Fixes
* [#10](https://github.com/C-S-D/alembic/pull/10) - `ToEctoSchema` and `ToParams` - [KronicDeth](https://github.com/KronicDeth)
  * Use `Alembic.ResourceIdentifier.t` in `Alembic.Relationship.t` for `data`'s value type.
  * Use `Alembic.Meta.t` in `Alembic.Relationship.t` for `meta`'s value type.
* [#13](https://github.com/C-S-D/alembic/pull/13) - [KronicDeth](https://github.com/KronicDeth)
  * Use `:unset` instead of `nil` for unset `%Alembic.Document{}` `data` as it was too difficult to properly infer when `nil` was unset and when it was a singleton that was not present.
  * `Alembic.Resource.to_params` now treats `nil` `%Alembic.Resource{}` `attributes` as `%{}` when building the params so invalid input from user does not cause an exception.
* [#14](https://github.com/C-S-D/alembic/pull/14) - Don't encode `ResourceIdentifier.meta` when it is `nil`, so that `"meta":null` doesn't occur in the encoded version. - [KronicDeth](https://github.com/KronicDeth)
* [#16](https://github.com/C-S-D/alembic/pull/16) - Add missing backquotes - [KronicDeth](https://github.com/KronicDeth)
* [#19](https://github.com/C-S-D/alembic/pull/19) - [KronicDeth](https://github.com/KronicDeth)
  * `Resource.to_ecto_schema` now ignores relationships that don't map to known associations, which manifested as an `ArgumentError` to `String.to_existing_atom`.
  * `Resource.to_ecto_schema` only sets the foreign key when the relationship is present, which prevent running `nil.id`.
* [#20](https://github.com/C-S-D/alembic/pull/20) - Indirect relationships - [KronicDeth](https://github.com/KronicDeth)
  * `to_params` and `to_ecto_schema` properly handles indirect relationships.
* [#21](https://github.com/C-S-D/alembic/pull/21) - Fix deprecation warnings for Ecto 1.1 - [KronicDeth](https://github.com/KronicDeth)
  * Use `Ecto.Changeset.cast/4` instead of `cast/3` to eliminate deprecation warning.
* [#22](https://github.com/C-S-D/alembic/pull/22) - Represent no relationship data different than null data - [KronicDeth](https://github.com/KronicDeth)
  * Like `Document`, `Relationship` needs to differentiate between `"data":null` in the JSON and no data key at all, so have `Relationship.t` default to `:unset` instead of `nil`, the same way `Document.t` works now.  This means adding a `Poison.Encoder` implementation to not encode the `:unset` and changing the `ToParams` behaviour to allow for an `{:error, :unset}` return that the `Relationship.to_params` can return when `data` is `:unset`, so that `Relationships.to_params` will skip including the output in the map of all relationship params.

### Incompatible Changes
* [#10](https://github.com/C-S-D/alembic/pull/10) - `ToEctoSchema` and `ToParams` - [KronicDeth](https://github.com/KronicDeth)
  * Removed the `Alembic.Relationship.resource_identifier` type that was made obsolete by `Alembic.ResourceIdentifier.t`
  * Updating relations by nesting attributes is no longer supported as it is not supported in the JSONAPI spec.
* [#17](https://github.com/C-S-D/alembic/pull/17) - Make `Link.href_from_json` private as it should have alway been. - [KronicDeth](https://github.com/KronicDeth)
* [#20](https://github.com/C-S-D/alembic/pull/20) - Indirect relationships - [KronicDeth](https://github.com/KronicDeth)
  * `ToParams` behaviour now requires `to_params/3` in addition to `to_params/2`
  * Remove `to_ecto_schema/3` that are no longer called because of recursion in `ToEctoSchema.to_ecto_schema/2`
    * `Relationship`
    * `Relationships`
    * `ResourceIdentifier`
    * `ResourceLinkage`

## v1.0.0
 
### Enhancements
* [#1](https://github.com/C-S-D/alembic/pull/1) - [KronicDeth](https://github.com/KronicDeth)
  * CircleCI build setup
  * JUnit formatter for CircleCI's test output parsing
* [#2](https://github.com/C-S-D/alembic/pull/2) - [KronicDeth](https://github.com/KronicDeth)
  * `mix test --cover` with CoverEx
  * Archive coverage reports on CircleCI
* [#3](https://github.com/C-S-D/alembic/pull/3) - [KronicDeth](https://github.com/KronicDeth)
  * Use `ex_doc` and `earmark` to generate documentation with `mix docs`
  * Use `mix inch (--pedantic)` to see coverage for documentation
* [#4](https://github.com/C-S-D/alembic/pull/4) - [KronicDeth](https://github.com/KronicDeth)
  * Add repository to [hexfaktor](http://hexfaktor.org/), so that outdated hex dependencies are automatically notified through CI.
  * Add [hexfaktor](http://hexfaktor.org/) badge to [README.md](README.md)
* [#5](https://github.com/C-S-D/alembic/pull/5) - [KronicDeth](https://github.com/KronicDeth)
  * Configure `mix credo` to run against `lib` and `test` to maintain consistency with Ruby projects that use `rubocop` on `lib` and `spec`.
  * Run `mix credo --strict` on CircleCI to check style and consistency in CI
* [#6](https://github.com/C-S-D/alembic/pull/6) - [KronicDeth](https://github.com/KronicDeth)
  * Use [`dialyze`](https://github.com/fishcakez/dialyze) for dialyzer access with `mix dialyze`
* [#7](https://github.com/C-S-D/alembic/pull/7) - Validation and conversion of JSON API errors Documents - [KronicDeth](https://github.com/KronicDeth)
  * JSON API errors documents can be validated and converted to `%Alembic.Document{}` using `Alembic.Document.from_json/2`.  Invalid documents return `{:error, %Alembic.Document{}}`.  The `%Alembic.Document{}` can be sent back to the sender, which can be validated on the other end using `from_json/2`.  Valid documents return `{:ok, %Alembic.Document{}}`.
* [#8](https://github.com/C-S-D/alembic/pull/8) - JSON API (non-errors) Documents - [KronicDeth](https://github.com/KronicDeth)
  * `Alembic.ResourceIdentifier`
  * `Alembic.ResourceLinkage`
  * `Alembic.Relationship`
  * `Alembic.Relationships`
  * `Alembic.Resource`
  * `Alembic.Document` can parse `from_json`, represent, and encode with `Poison.encode` all document format, including `data` and `meta`, in addition to the prior support for `errors`
  * `assert_idempotent` is defined in a module, `Alembic.FromJsonCase` under `test/support`, so it's no longer necessary to run `mix test <file> test/interpreter_server/api/from_json_test.exs` to get access to `assert_idempotent` in `<file>`.  

### Incompatible Changes
* [#8](https://github.com/C-S-D/alembic/pull/8) - JSON API (non-errors) Documents - [KronicDeth](https://github.com/KronicDeth)
  * `Alembic.FromJsonTest.assert_idempotent` has moved to `Alembic.FromJsonCase`.
