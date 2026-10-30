# Contributing to Lib-JS

Thanks for your interest in **Lib-JS**! This library brings JavaScript's built-in objects to pure
[Luau](https://luau.org/), and it is built by people who care about getting the details right. Bug
reports, spec-parity fixes, new methods, tests, and documentation improvements are all welcome.

By participating you agree to follow our [Code of Conduct](CODE_OF_CONDUCT.md). To report a
vulnerability, **do not open a public issue** - see [SECURITY.md](SECURITY.md).

## Table of contents

- [What Lib-JS is (and is not)](#what-lib-js-is-and-is-not)
- [Ways to contribute](#ways-to-contribute)
- [Getting set up](#getting-set-up)
- [Repository layout](#repository-layout)
- [Code style](#code-style)
- [Documentation comments](#documentation-comments)
- [Semantics and JS parity](#semantics-and-js-parity)
- [Tests](#tests)
- [Adding a method](#adding-a-method)
- [Adding a package](#adding-a-package)
- [Commits, pull requests, and the changelog](#commits-pull-requests-and-the-changelog)
- [Releases](#releases)
- [License](#license)

## What Lib-JS is (and is not)

- It is **fully based** on the [ECMAScript Language Specification](https://tc39.es/ecma262/) and
  [MDN Web Docs - JavaScript](https://developer.mozilla.org/en-US/docs/Web/JavaScript). When in doubt about
  behavior, the specification wins.
- It is written in **pure Luau**, not Lua, and must run on **any** Luau runtime (Roblox, [Lune](https://github.com/lune-org/lune),
  [Lute](https://github.com/luau-lang/lute)). Do not depend on Roblox-only APIs (`Instance`, `task`, `game`, ...) in library code
  unless the package already does so deliberately and says so in its docs.
- It is **not** a JavaScript interpreter. Where Luau cannot express something (`this`, `undefined` vs `null`, holes in
  arrays, mapped types, ...), we pick the closest honest behavior and **document the difference** instead of hiding it.
- The library is still under development. Some methods are not implemented yet, and that is exactly where help is most useful.

## Ways to contribute

- **Report a bug** - open an [issue](https://github.com/maneetoo/lib-js/issues) with a minimal reproduction, the expected
  result (ideally the JS result, with a link to the spec or MDN), and the actual result. Mention which runtime you used.
- **Fix a parity gap** - something behaves differently from JavaScript in a way that is not documented as a known limitation.
- **Implement a missing method or object** - check the open issues first and comment on the one you want, so work is not duplicated.
- **Improve tests and docs** - more edge cases (`NaN`, `-0`, `nil`, negative indices, huge lengths) are always welcome.
- **Performance** - these are hot-path primitives. Faster is great, as long as the semantics are unchanged and the tests still pass.

For larger changes (a new package, a public API change, a breaking behavior change), please open an issue to discuss it
**before** writing code.

## Getting set up

Lib-JS uses [`mise`](https://mise.jdx.dev/) to manage its toolchain (instead of Rokit/Aftman). With `mise` installed:

```sh
git clone https://github.com/<your-username>/lib-js.git
cd lib-js
mise install
```

This installs `luau-lsp`, `selene`, `wally`, `lune`, `rojo`, `luau`, and `stylua` (see [`mise.toml`](mise.toml)).

| Task             | Command            | What it does                                                    |
| ---------------- | ------------------ | --------------------------------------------------------------- |
| Format           | `mise run fmt`        | Formats all `.luau` files with StyLua                        |
| Check formatting | `mise run fmt-check`  | Fails if anything is not formatted                           |
| Lint             | `mise run lint`       | Runs Selene                                                  |
| Test             | `mise run test`       | Runs every suite in `tests/` with Lune                       |
| Build            | `mise run build`      | Runs `lint` and `fmt-check`, then builds `Slice.rbxlx` (Rojo)|
| Serve            | `mise run serve`      | Serves `default.project.json` to Roblox Studio via Rojo      |

Run a single suite with `lune run tests/run array` (suite names are the file names in `tests/`, without `.luau`).

Before you open a pull request, make sure this passes locally:

```sh
mise run fmt-check && mise run lint && mise run test
```

## Repository layout

```
.
├── packages/            # one directory per published package
│   ├── array/
│   │   ├── src/
│   │   │   ├── init.luau          # the module itself (`Array`)
│   │   │   ├── from.luau          # one file per static
│   │   │   ├── __toArray.luau     # `__` prefix = internal, not public API
│   │   │   └── prototype/         # one file per prototype method
│   │   ├── default.project.json   # Rojo node name (e.g. "Array")
│   │   ├── wally.toml
│   │   ├── README.md
│   │   └── LICENSE
│   ├── ecmascript/      # spec abstract operations (ToIntegerOrInfinity, SameValueZero, ...)
│   ├── es17types/       # shared types-only module
│   ├── lib-js/          # umbrella package re-exporting everything
│   └── ...              # boolean, error, json, map, math, number, object, promise, set,
│                        # string, symbol, timers, weakmap, weakref, weakset, globalthis,
│                        # instanceof, iterate
├── tests/               # Lune test suites (+ the shared harness and module loader)
├── default.project.json # Rojo project: everything in packages/ becomes ReplicatedStorage/lib-js
├── mise.toml  stylua.toml  selene.toml  .luaurc
└── CHANGELOG.md
```

Conventions worth knowing:

- **Complex objects are folders, simple ones are a single `init.luau`.** `Array`, `Object`, `String`, `Number`, `Math`,
  `Symbol`, and `Timers` split each static into its own file; `Map`, `Set`, `WeakMap`, and friends are one file.
- **Prototype methods live in `src/prototype/<method>.luau`**, one method per file, and are wired up in `prototype/init.luau`.
- **Internal modules start with `__`** (`__shared`, `__toArray`, `__staticProps`, ...). They are not public API and may change
  at any time. Keep helpers small - logic used by one method belongs in that method's file.
- **Spec abstract operations live in `packages/ecmascript`** and keep their spec names in PascalCase
  (`ToIntegerOrInfinity`, `SameValueZero`, ...), each file linking its section of the specification. Reuse them instead of
  re-implementing the conversion in each method.
- **Each package has its own `LICENSE`, `README.md`, `wally.toml`, and `default.project.json`**, and its `default.project.json`
  `name` is how other packages `require` it.

## Code style

Formatting and linting are enforced by tools, so you rarely need to think about them - run `mise run fmt` and `mise run lint`.
The conventions below cover what the tools do not.

### Formatting (StyLua)

Configured in [`stylua.toml`](stylua.toml): **tabs** (width 4), **120 columns**, Unix line endings, double quotes,
parentheses always on calls (`call_parentheses = "Always"`), no collapsed single-line statements, no blank-line padding
inside blocks, and sorted `require`s.

### Strict mode and types

- Every source file starts with `--!strict`.
- Annotate all function parameters and return types. Use generics (`<T, U>`) for container methods.
- Reuse the shared types from `ES17-Types` (`esTypes.Array<T>`, `esTypes.Table<K, V>`, ...) rather than redefining them.
- Parameters that mirror "any JS value" are typed `unknown` (or `any` where a conversion operation accepts anything).
  Narrow with a real check, not a bare `::` cast, wherever correctness depends on it.

### Bindings

- Use `const` for every binding that is never reassigned, and `local` only for values that change (loop accumulators,
  swapped buffers, ...). Declare functions as `const function name(...)` unless they are forward-declared or reassigned.
- Name things like the JavaScript API they implement: modules and methods use the JS name (`fromEntries`, `copyWithin`,
  `toSorted`), and spec abstract operations keep the spec's PascalCase. Internal helpers use `camelCase`.

### Requires

Modules reference each other by their **Rojo node name**, not by file path from the repository root:

```lua
const ECMAScript = require("../../ECMAScript") -- another package, from prototype/
const esTypes = require("../../ES17-Types")
const prototype = require("@self/prototype")   -- a sibling in the same package
```

The test loader (`tests/_loader.luau`) resolves exactly these forms, so a new `require` shape will not work in tests
unless the loader is taught about it. Stick to the existing ones.

### Errors

- Throw JavaScript-style errors from the `Error` package (`TypeError`, `RangeError`, ...) with a message that **names the
  method**: `error(TypeError.new("Array.prototype.map: callback is not a function"))`.
- When a plain `error("...", 2)` is appropriate, use level `2` so the error is reported at the caller, not inside the library.
- Fail with a clear message instead of letting Luau raise something opaque (for example `table index is nil`).

### Performance

These functions are called in tight loops, so:

- Keep the common path free of avoidable work: do cheap checks first, build error messages **only on failure**.
- Preallocate with `table.create`, move ranges with `table.move`, and avoid creating closures or intermediate tables in loops.
- Explain non-obvious optimizations in a short comment, as the existing code does.
- Do not trade correctness for speed. If you can show a measurable win, include numbers in the pull request.

### Immutability

Public module tables and `prototype` tables are frozen with `table.freeze` before being returned. Keep doing that for new modules.

### Comments

Comments explain **why**, not what. A comment that records a spec rule, a Luau limitation, or a performance trick is valuable;
one that restates the next line is noise.

## Documentation comments

Public APIs are documented with [Moonwave](https://eryn.io/moonwave/)-style doc comments (`--[=[ ... ]=]`) directly in the
source. Follow the existing pattern.

A file opens with a `@class` block that links the MDN page:

```lua
--!strict

--[=[
	@class at

	A Luau implementation of JavaScript's [`Array.prototype.at()`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/at).
]=]
```

and the function carries a `@within` block describing parameters and the return value:

```lua
--[=[
	@within at
	@param array Array<T> -- the array to read from
	@param index number? -- position, starting at 0. Negative values count from the end.
	@return T? -- the element, or `nil` if the position is out of range

	Returns the element at `index`, as JS `Array.prototype.at`. The receiver is the
	first argument, so call `Array.prototype.at(arr, -1)`.
]=]
```

Rules of thumb:

- Document **every deviation from JavaScript** with a `:::caution` block (0-based vs 1-based indices, no `thisArg`, `nil`
  vs `undefined`, key coercion, ordering differences, ...). Use `:::note` for useful non-warning remarks.
- Mark internal modules and helpers with `@private`.
- Wrap prose at roughly 80-100 columns inside doc comments, and use plain, direct sentences.

## Semantics and JS parity

Match the specification, then document where Luau forces you to differ. In practice:

- **The receiver is the first argument.** Arrays are plain tables with no metatable, so you write
  `Array.prototype.push(arr, x)`, not `arr:push(x)`.
- **Indices follow JavaScript at the API boundary.** Array methods take and return **0-based** indices and callbacks receive
  0-based indices, even though `arr[1]` is the first element of the underlying table. If a method deliberately deviates (for
  example, a callback index that is 1-based), say so in a `:::note`.
- **`undefined` is `nil`.** Luau cannot distinguish a `nil` element from a missing one, and there are no sparse-array holes.
  Document what that means for your method.
- **There is no `this` and no `thisArg`.** Callbacks get exactly the arguments JS gives them; users capture context in closures.
- **Do not silently diverge.** If you cannot match a corner case (`NaN`/`nil` table keys, UTF-16 vs UTF-8 ordering, number-to-string
  precision, ...), either raise a clear error or document the difference - never return a quietly wrong answer.
- **Link the spec.** Abstract operations should cite their section of [ECMA-262](https://tc39.es/ecma262/), and methods should
  link the matching MDN page.

## Tests

Tests are plain Luau scripts run by [Lune](https://github.com/lune-org/lune) - there is no external test framework. Each file in
`tests/` is a suite for one package, and `tests/run.luau` discovers and runs all of them (files starting with `_` are internal).

A suite loads packages through `tests/_loader.luau` (which resolves requires the way Rojo does) and uses the small harness in
`tests/_init.luau`:

```lua
--!strict
-- Math: constants and the non-trivial ported functions.

local T = require("./_init").new("Math")
local loader = require("./_loader")

local Math = loader.loadPackage("Math") :: any

return function(): (number, number)
	-- sign
	do
		T:check("sign positive", Math.sign(5) == 1)
		T:check("sign -0 is -0", 1 / Math.sign(-0) == -math.huge)
		T:expectError("hypot rejects a non-number", function()
			Math.hypot({})
		end)
	end

	T:finish()
	return T.passed, T.failed
end
```

Guidelines:

- **Add or update tests with every behavior change.** A bug fix should include a test that fails without the fix.
- Group related checks in a `do ... end` block with a short comment naming the method.
- Give every check a **descriptive message** - it is the only thing printed when a check fails.
- Cover the edges JavaScript is known for: `NaN`, `+0`/`-0` (test with `1 / x`), `Infinity`, negative and out-of-range
  indices, empty inputs, `nil` arguments, non-callable callbacks, and mutation during iteration.
- For a new package, add `tests/<package>.luau`.
- Compare against real JavaScript results where you can (`node -e "..."` is a quick oracle) and mention it in the PR.

## Adding a method

1. Find the spec section and MDN page for the method.
2. Create `packages/<package>/src/<method>.luau` (a static) or `src/prototype/<method>.luau` (a prototype method) with the
   `--!strict` header, the `@class` and `@within` doc comments, and `const function <method>(...)`.
3. Convert arguments with the operations in `packages/ecmascript` (`ToIntegerOrInfinity`, `ToLength`, `IsCallable`, ...) so
   coercion matches the spec.
4. Wire it up: add it to the module table in `init.luau` (or to `prototype/init.luau`).
5. Document every deviation from JS with `:::caution`.
6. Add tests in `tests/<package>.luau`.
7. Run `mise run fmt`, `mise run lint`, and `mise run test`.
8. Add an entry to `CHANGELOG.md` under `Unreleased`.

## Adding a package

New packages are rare and should be discussed in an issue first. When one is approved:

1. Create `packages/<name>/` with `src/init.luau`, `README.md`, a copy of `LICENSE`, `wally.toml`, and `default.project.json`
   (its `name` is the PascalCase node name other packages will `require`).
2. Model `wally.toml` on an existing package: `name = "maneetoo/<name>"`, `license = "MIT"`, `authors = ["maneetoo"]`,
   `realm = "shared"`, the same `registry` and `repository`, and dependencies on sibling `maneetoo/*` packages at the
   **current version** used by the rest of the repository.
3. Add the package to `packages/lib-js` (its `wally.toml` dependencies and its `init.luau` re-export and type exports).
4. Copy the badge header from an existing package README.
5. Add a test suite and a changelog entry.

## Commits, pull requests, and the changelog

- **Fork, then branch from `main`.** Use a short descriptive branch name (`fix-array-flat-depth`, `feat-string-localecompare`).
- **Keep pull requests focused.** One logical change per PR; unrelated refactors go in their own PR.
- **Commit messages:** a short, imperative summary. We lean towards [Conventional Commits](https://www.conventionalcommits.org/)
  (`fix: ...`, `feat: ...`, `docs: ...`, `test: ...`, `chore: ...`), which is what the release automation itself uses.
- **In the PR description**, explain what changed and why, link the issue, link the spec/MDN section, and note any
  documented deviation from JS. If you changed performance-sensitive code, include before/after numbers.
- **Checklist before requesting review:**
  - [ ] `mise run fmt-check`, `mise run lint`, and `mise run test` pass
  - [ ] Tests added or updated
  - [ ] Doc comments added or updated (including `:::caution` for any JS deviation)
  - [ ] `CHANGELOG.md` updated
  - [ ] No version numbers bumped (see below)
- **Changelog.** `CHANGELOG.md` follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
  [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Add your entry under an `Unreleased` heading, in the right
  section (`Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`). Mark breaking changes clearly.

Reviews are done by the maintainer in their free time, so please be patient. Feedback is about the code, never the person.

## Releases

Releases are cut by the maintainer via the **Release** GitHub Actions workflow. It validates the version (`X.Y.Z` or
`X.Y.Z-rc.N`), bumps **every** `wally.toml` (package versions and the dependencies on sibling `maneetoo/*` packages) in
lockstep, builds the model with Rojo, publishes each package to [Wally](https://wally.run/), and creates the GitHub release.
Because of that:

- **Do not change versions in `wally.toml` files** in your pull requests.
- All packages share one version number.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE) that covers the project.
