use rust_demo::hello_dir::hello_mod::{hello_fn, world_fn};

fn main() {
    println!("{}", hello_fn().to_owned() + world_fn());
}
