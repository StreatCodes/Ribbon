## Ribbon, a small language that compiles to [WAST](https://developer.mozilla.org/en-US/docs/WebAssembly/Understanding_the_text_format)

This language is more of a learning experience than anything serious.

- Currently only the parser is partially implemented

### Build / run

Install the latest Zig

`zig build run` from the root directory of this project.

### Why compile to WAST?

Most WASM runtimes accept WAST, it's easier for me to understand and read,
optimisations and WAST->WASM compilation can be done with third-party tools.

I suspect most applications in future will target WASM, Running untrusted code
on your machine needs to be heavily sandboxed and the core WASM spec defines a
simple foundation to achieve that. I believe in a future where applications will
run simply by clicking a URL. Much like the web works today, however browsers
weren't originally built for this purpose. This language is an attempt at
designing component based applications much like how React, flutter and SwiftUI
apps are written today. Really it's just a language that can easily generate a
tree of components with simple semantics to manage state. These components will
execute from a WASM runtime and be displayed with a UI library written with
WebGPU (which currently doesn't exist).
