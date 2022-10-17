use rust_demo::hello_dir::hello_mod::{hello_fn, world_fn};

#[test]
fn integr_hello() {
    assert_eq!("Hello, world!", hello_fn().to_owned() + world_fn());
}
