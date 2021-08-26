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

    public fun swap_exact_token_for_token<X: store, Y: store>(
        signer: &signer,
        amount_x_in: u128,
        amount_y_out_min: u128,
    ) {
        //test

    }

    public fun swap_token_for_exact_token<X: store, Y: store>(
        signer: &signer,
        amount_x_in_max: u128,
        amount_y_out: u128,
    ) {

        //test
    }

}
}