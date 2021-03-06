#[no_mangle]
pub unsafe extern "C" fn add_func(op1: i32, op2: i32) -> i32 {
    op1 + op2
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
