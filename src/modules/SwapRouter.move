address 0x100 {
module Router {
    use 0x1::Signer;
    use 0x100::SwapConfig::Config;
    use 0x100::SwapLibrary;
    use 0x100::LPToken::LPToken;

    const CONFIG_ADDRESS = @0x100;

    const IDENTICAL_TOKEN: u64 = 100001;
    const SWAP_PAIR_NOT_EXISTS: u64 = 100002;
    const INSUFFICIENT_X_AMOUNT: u64 = 100003;
    const INSUFFICIENT_Y_AMOUNT: u64 = 100004;
    const OVERLIMIT_X_DESIRED: u64 = 100005;

    fun _add_liquidity<X: store, Y: store>(
        signer: &signer,
        amount_x_desired: u128,
        amount_y_desired: u128,
        amount_x_min: u128,
        amount_y_min: u128
    ) {
        // swap pair exists
        let address = Signer::address_of(signer);
        assert(exists<LPToken<X, Y>>(address), SWAP_PAIR_NOT_EXISTS);
        let (reserve_x, reserve_y) = SwapPair::get_reserves<X, Y>(address);
        let (amount_x, amount_y);
        if (reserve_x == 0 && reserve_y == 0) {
            (amount_x, amount_y) = (amount_x_desired, amount_y_desired);
        } else {
            let amount_y_optimal = SwapLibrary.quote(amount_x_desired, reserve_x, reserve_y);
            if (amount_y_optimal <= amount_y_desired) {
                assert(amount_y_optimal >= amount_y_min, INSUFFICIENT_Y_AMOUNT);
                return (amount_x_desired, amount_y_optimal)
            } else {
                let amount_x_optimal = quote(amount_y_desired, reserve_y, reserve_x);
                assert(amount_x_optimal <= amount_x_desired, OVERLIMIT_X_DESIRED);
                assert(amount_x_optimal >= amount_x_min, INSUFFICIENT_X_AMOUNT);
                return (amount_x_optimal, amount_y_desired)
            };
        };
    }

    // add liquidity
    public fun add_liquidity<X: store, Y: store>(
        signer: &signer,
        amount_x_desired: u128,
        amount_y_desired: u128,
        amount_x_min: u128,
        amount_y_min: u128
    ) {
        // order x and y to avoid duplicates
        let order = SwapLibrary::compare_token<X, Y>();
        assert(order != 0, IDENTICAL_TOKEN);
        if (order == 1) {
            // calculate the amount of x and y
            let (amount_x, amount_y) = _add_liquidity<X, Y>(signer, amount_x_desired, amount_y_desired, amount_x_min, amount_y_min);
            // add liquidity with amount
            SwapPair::add_liquidity<X, Y>(signer, amount_x, amount_y);
        } else {
            let (amount_y, amount_x) = _add_liquidity<Y, X>(signer, amount_y_desired, amount_x_desired, amount_y_min, amount_x_min);
            SwapPair::add_liquidity<Y, X>(signer, amount_y, amount_x);
        };
    }

    public fun remove_liquidity<X: store, Y: store>(
        signer: &signer,
        liquidity: u128,
        amount_x_min: u128,
        amount_y_min: u128
    ) {
        
    }

    // get y
    // Specify the number of tokens sold to get another token
    public fun swap_exact_token_for_token<X: store, Y: store>(
        signer: &signer,
        amount_x_in: u128,
        amount_y_out_min: u128
    ) {
        // get y
        SwapLibrary::swap_pair_token_auto_accept<Y>(signer);
        let (reserve_x, reserve_y) = SwapPair::get_reserves<X, Y>();

        let y_out = get_amount_out(amount_x_in, reserve_x, reserve_y);
        assert(y_out >= amount_y_out_min, ERROR_ROUTER_Y_OUT_LESSTHAN_EXPECTED);
        
        let token_x = Account::withdraw<X>(signer, amount_x_in);
        let (token_x_out, token_y_out) = SwapPair::swap<X, Y>(token_x, y_out, Token::zero(), 0);
        
        Token::destroy_zero(token_x_out);
        Account::deposit(Signer::address_of(signer), token_y_out);
    }

    // get x 
    // Specify the number of tokens to buy and sell another token
    public fun swap_token_for_exact_token<X: store, Y: store>(
        signer: &signer,
        // Number of assets you want to buy
        amount_y_out: u128,
        // Maximum value of purchased assets
        amount_x_in_max: u128
    ) {
        // get x
        SwapLibrary::swap_pair_token_auto_accept<X>(signer);
        let (reserve_x, reserve_y) = SwapPair::get_reserves<X, Y>();

        let x_in = get_amount_in(amount_y_out, reserve_x, reserve_y);
        assert(x_in <= amount_x_in_max, ERROR_ROUTER_IN_OVER_LIMIT_MAX);
        
        // do actual swap
        let token_x = Account::withdraw<X>(signer, x_in);

        let (token_x_out, token_y_out) = SwapPair::swap<X, Y>(token_x, amount_y_out, Token::zero(), 0);
        
        Token::destroy_zero(token_x_out);
        Account::deposit(Signer::address_of(signer), token_y_out);
    }


    public fun get_amount_in(amount_out: u128, reserve_in: u128, reserve_out: u128): u128 {
        assert(amount_out > 0, ERROR_ROUTER_INSUFFICIENT_OUTPUT_AMOUNT);
        assert(reserve_in > 0 && reserve_out > 0, ERROR_ROUTER_INSUFFICIENT_LIQUIDITY);
        let numerator = reserve_in * amount_out * 1000;
        // todo denominator = reserveOut.sub(amountOut).mul(997); 
        let denominator = (reserve_out - amount_out) * 997;
        (numerator / denominator) + 1
    }

    public fun get_amount_out(amount_in: u128, reserve_in: u128, reserve_out: u128): u128 {
        assert(amount_in > 0, ERROR_ROUTER_INSUFFICIENT_INPUT_AMOUNT);
        assert(reserve_in > 0 && reserve_out > 0, ERROR_ROUTER_INSUFFICIENT_LIQUIDITY);
        let amount_in_with_fee = amount_in * 997;
        let numerator = amount_in_with_fee * reserve_out;
        let denominator = reserve_in * 10000 + amount_in_with_fee;
        numerator / denominator
    }

}
}