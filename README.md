mruby-cr
========

Automatically generate mruby bindings for
Crystal.

## Requirements

Assumed tools installed locally:

* llvm with clang support
* curl
* unzip
* ruby

## Usage

```
$ mruby-cr default
```

The result will drop a `mruby.cr` file in the
current directory, along with an installation
of mruby built and ready for linking.

## Configuration file

A configuration file can be supplied in JSON
format. Key names are the same as flag names
with the dash replaced with underscore. For
example:

```
$ mruby-cr default --output-directory=src/
```

can be defined in the configuration file as:

```json
{
  "output_directory": "src/"
}
```

If a configuration defined at `.mruby-cr` it
will be automatically loaded.

## Inspiration

* https://github.com/fazibear/crystal_lib_gen
