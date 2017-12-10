FFIGen.generate(
  module_name: "MRuby",
  ffi_lib: "mruby",
  mruby_lib: $opts[:mruby_libdir],
  headers: %w[
    mruby.h
    mruby/class.h
    mruby/compile.h
  ],
  cpath: '/usr/lib/gcc/x86_64-unknown-linux-gnu/7.2/include',
  cflags: ["-I#{$opts[:mruby_dir]}/include"] + $opts[:cflags],
  prefixes: ["mrb", "mrbc"],
  output: File.join($opts.fetch(:output_directory, '.'), 'mruby.cr')
)
