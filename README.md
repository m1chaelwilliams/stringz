# stringz

A string implementation for the zig programming language.

## Usage

```zig
var gpa = std.heap.generalPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const hello = try String.initFromSlice(allocator, "hello ");
defer hello.deinit();

var greeting = try hello.clone();
defer greeting.deinit();

try greeting.pushString("world!");
std.debug.print("{s}\n", .{greeting.slice()});
```

## Install

```bash
zig fetch --save git+https://github.com/m1chaelwilliams/stringz.git
```

In `build.zig`:

```zig
const dep_stringz = b.dependency("stringz", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("stringz", dep_zstbi.module("root"));
```

## License

This code is licensed under MIT.
