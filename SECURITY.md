# Security Policy

Thank you for helping keep **Lib-JS** and the people who use it safe.

## Supported versions

Lib-JS is under active development. Security fixes are provided for the **latest published release** and for the
current development line on `main`. Older releases are not patched - please upgrade.

| Version                            | Supported |
| ---------------------------------- | --------- |
| Latest release (and pre-release)   | Yes       |
| `main` branch                      | Yes       |
| Anything older than the latest     | No        |

All packages in this repository (`maneetoo/lib-js` and the individual `maneetoo/*` packages such as `array`, `object`,
`string`, `json`, `promise`, `timers`, ...) are versioned together, so a fix is released for all of them at once.

## Reporting a vulnerability

**Please do not report security vulnerabilities through public GitHub issues, pull requests, or Discord.**

Report privately using GitHub's private vulnerability reporting:

1. Go to the repository's [**Security** tab](https://github.com/maneetoo/lib-js/security).
2. Click **Report a vulnerability** (or open a [new advisory](https://github.com/maneetoo/lib-js/security/advisories/new)).
3. Fill in the details below.

If you cannot use GitHub's reporting form, send a direct message to the maintainer, [@maneetoo](https://github.com/maneetoo),
and ask for a private channel. Do not include exploit details in the first message.

### What to include

A good report makes it quick to reproduce and fix:

- The affected package(s), module(s), and version or commit.
- The runtime you tested on (Roblox, Lune, Lute, ...), and its version.
- A clear description of the issue and its impact.
- Minimal reproduction steps or a proof-of-concept script.
- Any suggested fix or mitigation, if you have one.

## What to expect

This is a volunteer-maintained project, so these are goals, not guarantees:

| Step                                   | Target                     |
| -------------------------------------- | -------------------------- |
| Acknowledgement of your report         | within 7 days              |
| Initial assessment (valid / not valid) | within 14 days             |
| Fix or mitigation for confirmed issues | as soon as reasonably possible, depending on severity |

We will keep you updated, work with you on a coordinated disclosure date, and publish a GitHub Security Advisory
and a note in the [changelog](CHANGELOG.md) when the fix is released. Reporters are credited in the advisory
unless they ask to remain anonymous.

Please give us a reasonable amount of time to release a fix **before** disclosing the issue publicly.

## Scope

Lib-JS is a pure Luau library of JavaScript-compatible built-ins. Examples of issues that are in scope:

- Code execution or sandbox escape through a library function, for example through unsafe use of `loadstring`/`getfenv`/`setfenv`
  or equivalent.
- **Prototype or metatable tampering** that lets untrusted input alter the behavior of shared, supposedly frozen tables
  (`Object`, `Array.prototype`, ...).
- **Denial of service** from small inputs, such as unbounded memory growth, catastrophic running time, or unbounded recursion
  in `JSON.parse`/`JSON.stringify`, `String`, or `Array` methods on attacker-controlled data.
- Memory-safety or integrity problems in the scheduler (`Timers`) or `Promise` implementation, such as callbacks run in the wrong
  context or lost errors that hide a security-relevant failure.
- Compromise of the **build, release, or publishing pipeline** (GitHub Actions workflows, Wally/Pesde packages, release artifacts).

Examples that are generally **not** security vulnerabilities:

- Behavior that differs from the ECMAScript specification without a security impact. These are regular bugs: please open a
  public issue (see [CONTRIBUTING.md](CONTRIBUTING.md)).
- Known, documented limitations (for example `undefined` vs `nil`, UTF-8 byte ordering in `sort`, number formatting precision).
- Vulnerabilities in Luau, Roblox, Lune, Lute, Wally, Pesde, or other third-party software. Please report those to their
  respective maintainers.
- Issues that need an attacker to already control the process running the library (for example by replacing core modules).
- Misuse of the library in your own code, or missing hardening on input you chose not to validate.

If you are not sure whether something is in scope, report it privately anyway - we would rather hear about it.

## Safe harbor

We consider good-faith security research that follows this policy to be authorized. If you make a good-faith effort to avoid
privacy violations, data destruction, and service disruption, and only test against your own installations, we will not
pursue or support action against you.

## For users of the library

- Pin an exact version in `wally.toml` or `pesde.toml` and review updates, especially pre-releases (`-rc.N`).
- Treat data from outside your game or application (network input, player input, JSON files) as untrusted. Validate it, and
  limit its size before passing it to parsing and string functions.
- Do not run untrusted code or modules in the same environment as library tables that you rely on staying unmodified.
- Watch the repository's [Security advisories](https://github.com/maneetoo/lib-js/security/advisories) and the
  [changelog](CHANGELOG.md).
