//use dart_bindgen::{config::*, Codegen};

use std::result::Result;

fn main() -> Result<(), ()> {
    let crate_dir = std::env::var("CARGO_MANIFEST_DIR").unwrap();
    let mut config = cbindgen::Config::default();
    config.language = cbindgen::Language::C;
    cbindgen::Builder::new()
        .with_crate(crate_dir)
        .with_config(config)
        .generate()
        .expect("Unable to generate bindings")
        .write_to_file("skmtdart_ffi.h");
    /*
        let config = DynamicLibraryConfig {
            ios: DynamicLibraryCreationMode::Executable.into(),
            android: DynamicLibraryCreationMode::open("libworklib.so").into(),
            linux: DynamicLibraryCreationMode::open("libworklib.so").into(),
            windows: DynamicLibraryCreationMode::open("worklib.dll").into(),
            ..Default::default()
        };
        // load the c header file, with config and lib name
        let codegen = Codegen::builder()
            .with_src_header("binding.h")
            .with_lib_name("libworklib")
            .with_config(config)
            .build()
            .unwrap();
        // generate the dart code and get the bindings back
        let bindings = codegen.generate().unwrap();
        // write the bindings to your dart package
        // and start using it to write your own high level abstraction.
        bindings
            .write_to_file("ffi.dart")
            .unwrap();
    */
    Ok(())
}
