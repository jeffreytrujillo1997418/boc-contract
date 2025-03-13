module boc::math {

    const MAX_U64: u64 = 18446744073709551615;

    const ERR_DIVIDE_BY_ZERO: u64 = 2000;

    const ERR_NOT_PROPORTION: u64 = 2001;

    const OVERFLOW: u64 = 2002;
    
    public fun mul_u128_u64_div_u64_result_u64(x: u128, y: u64, z:u64): u64 {
        assert!(z != 0, ERR_DIVIDE_BY_ZERO);
        let res = x * (y as u128) / (z as u128);
        assert_can_cast_to_u64(res);
        (res as u64)
    }

    fun assert_can_cast_to_u64(x: u128) {
        assert!(x <= (MAX_U64 as u128), OVERFLOW);
    }

    public fun calculate_proportion_of_u64_with_u128_denominator(x: u64, numerator: u64, denominator: u128): u64 {
        assert!(denominator != 0, ERR_DIVIDE_BY_ZERO);
        
        
        assert!(denominator >= (numerator as u128), ERR_NOT_PROPORTION);
        ((x as u128) * (numerator as u128) / (denominator) as u64)
    }
}