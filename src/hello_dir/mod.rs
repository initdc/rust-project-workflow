/// Module hello_mod
/// - hello_fn()
/// - world_fn()
pub mod hello_mod {

    /// Function hello_fn()
    /// return "Hello, "
    /// ```rust
    /// use rust_demo::hello_dir::hello_mod::hello_fn;
    /// println!("{}", hello_fn());
    /// assert_eq!("Hello, ", hello_fn());
    /// ```
    pub fn hello_fn() -> &'static str {
        return "Hello, ";
    }

    /// Function world_fn()
    /// return "world!"
    /// ```rust, should_panic
    /// use rust_demo::hello_dir::hello_mod::world_fn;
    /// println!("{}", world_fn());
    /// assert_eq!("Hello, ", world_fn());
    /// ```
    pub fn world_fn() -> &'static str {
        return "world!";
    }
}

/// ```rust
/// use rust_demo::hello_dir::hello_mod::{hello_fn, world_fn};
/// println!("{}", hello_fn().to_owned() + world_fn());
/// ```
#[cfg(doctest)]
mod doctests {
    #[test]
    fn doctest_hello() {
        assert_eq!("Hello, world!", hello_fn().to_owned() + world_fn());
    }
}

#[cfg(test)]
mod tests {
    use crate::hello_dir::hello_mod::{hello_fn, world_fn};

    #[test]
    fn unit_hello_1() {
        assert_eq!("Hello, ", hello_fn());
    }

    #[test]
    #[should_panic]
    fn unit_hello_2() {
        assert_eq!("world!", hello_fn());
    }

    #[test]
    fn unit_world_1() {
        assert_eq!("world!", world_fn());
    }

    #[test]
    #[ignore]
    fn unit_world_2() {
        assert_ne!("Hello, ", world_fn());
    }
}
