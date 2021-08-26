address 0x100 {
module Router {
    public fun add_liquidity<X: store, Y: store>(
        signer: &signer,
        amount_x_desired: u128,
        amount_y_desired: u128,
        amount_x_min: u128,
        amount_y_min: u128
    ) {

    }

    public fun add_liquidity<X: store, Y: store>(
        signer: &signer,
        liquidity: u128,
        amount_x_min: u128,
        amount_y_min: u128
    ) {
        
    }

    public fun swap_exact_token_for_token<X: store, Y: store>(
        signer: &signer,
        amount_in: u128,
        amount_out_min: u128
    ) {
        // auto accept
        swap_pair_token_auto_accept<Y>(signer);
        let order = TokenPair::compare_token<X, Y>();
        assert(order != 0, ERROR_ROUTER_INVALID_TOKEN_PAIR);
        let (reserve_x, reserve_y) = get_reserves<X, Y>();
        let amount_out = get_amount_out(amount_in, reserve_x, reserve_y);
        assert(amount_out >= amount_out_min, ERROR_ROUTER_Y_OUT_LESSTHAN_EXPECTED);
        
        let token_x = Account::withdraw<X>(signer, amount_in);
        let (token_x_out, token_y_out);
        if (order == 1) {
            (token_x_out, token_y_out) = TokenSwap::swap<X, Y>(token_x, amount_out, Token::zero(), 0);
        } else {
            (token_y_out, token_x_out) = TokenSwap::swap<Y, X>(Token::zero(), 0, token_x, amount_out);
        };
        Token::destroy_zero(token_x_out);
        Account::deposit(Signer::address_of(signer), token_y_out);
    }

    public fun swap_token_for_exact_token<X: store, Y: store>(
        signer: &signer,
        amount_out: u128,
        amount_in_max: u128,
    ) {
        // auto accept
        swap_pair_token_auto_accept<X>(signer);
        let order = TokenPair::compare_token<X, Y>();
        assert(order != 0, ERROR_ROUTER_INVALID_TOKEN_PAIR);
        let (reserve_x, reserve_y) = get_reserves<X, Y>();

        let amount_in = get_amount_in(amount_out, reserve_x, reserve_y);
        assert(x_in <= amount_in_max, ERROR_ROUTER_IN_OVER_LIMIT_MAX);
        
        // do actual swap
        let token_x = Account::withdraw<X>(signer, amount_in);

        let (token_x_out, token_y_out);
        if (order == 1) {
            (token_x_out, token_y_out) = TokenSwap::swap<X, Y>(token_x, amount_out, Token::zero(), 0);
        } else {
            (token_y_out, token_x_out) = TokenSwap::swap<Y, X>(Token::zero(), 0, token_x, amount_out);
        };
        Token::destroy_zero(token_x_out);
        Account::deposit(Signer::address_of(signer), token_y_out);
    }

    public fun get_reserves<X: store, Y: store>(): (u128, u128) {
        let order = TokenPair::compare_token<X, Y>();
        assert(order != 0, ERROR_ROUTER_INVALID_TOKEN_PAIR);
        if (order == 1) {
            TokenPair::get_reserves<X, Y>()
        } else {
            let (y, x) = TokenPair::get_reserves<Y, X>();
            (x, y)
        }
    }

    public fun swap_pair_token_auto_accept<Token: store>(signer: &signer) {
        if (!Account::is_accepts_token<Token>(Signer::address_of(signer))) {
            Account::do_accept_token<Token>(signer);
        };
    }

    public fun get_amount_in(amount_out: u128, reserve_in: u128, reserve_out: u128): u128 {
        assert(amount_out > 0, ERROR_ROUTER_INSUFFICIENT_OUTPUT_AMOUNT);
        assert(reserve_in > 0 && reserve_out > 0, ERROR_ROUTER_INSUFFICIENT_LIQUIDITY);
        let numerator = reserve_in * amount_out * 1000;
        // todo denominator = reserveOut.sub(amountOut).mul(997); 不知道对不对
        let denominator = (reserve_out - amount_out) * 997;
        (numerator / denominator) + 1
    }

    public fun get_amount_out(amount_in: u128, reserve_in: u128, reserve_out: u128): u128 {
        assert(amount_in > 0, ERROR_ROUTER_INSUFFICIENT_INPUT_AMOUNT);
        assert(reserve_in > 0 && reserve_out > 0, ERROR_ROUTER_INSUFFICIENT_LIQUIDITY);
        let amount_in_with_fee = amount_in * 997;
        let numerator = amount_in_with_fee * reserve_out;
        let denominator = reserve_in * 1000 + amount_in_with_fee;
        numerator / denominator
    }

}
}