address 0x100 {
module SwapLibrary {
    use 0x1::Token;
    use 0x1::BCS;
    use 0x1::Compare;
    use 0x1::Math;

    const INSUFFICIENT_AMOUNT: u64 = 300001;
    const INSUFFICIENT_LIQUIDITY: u64 = 300002;
    
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    public fun compare_token<X: store, Y: store>(): u8 {
        let x_bytes = BCS::to_bytes<Token::TokenCode>(&Token::token_code<X>());
        let y_bytes = BCS::to_bytes<Token::TokenCode>(&Token::token_code<Y>());
        let ret : u8 = Compare::cmp_bcs_bytes(&x_bytes, &y_bytes);
        ret
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    public fun quote(amount_x: u128, reserve_x: u128, reserve_x: u128): u128 {
        assert(amount_x > 0, INSUFFICIENT_AMOUNT);
        assert(reserve_x > 0 && reserve_y > 0, INSUFFICIENT_LIQUIDITY);
        Math::mul_div(amount_x, reserve_y, reserve_x)
    }

}
}