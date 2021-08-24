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

    //指定买进代币数量，卖出另一种代币
    public fun swap_exact_token_for_token<X: store, Y: store>(
        // 签名，可以拿到它的地址 to 不需要了 
        signer: &signer,
        // 买进的资产的数量
        amount_x_in: u128,
        // 指定卖入资产的最大值
        amount_y_out_min: u128,
    ) {
        // auto accept
        swap_pair_token_auto_accept<Y>(signer);
        // 验证 令牌
        let order = TokenPair::compare_token<X, Y>();
        // 无效令牌
        assert(order != 0, ERROR_ROUTER_INVALID_TOKEN_PAIR);

        // 计算输出的y
        let (reserve_x, reserve_y) = get_reserves<X, Y>();
        let y_out = get_amount_out(amount_x_in, reserve_x, reserve_y);
        assert(y_out >= amount_y_out_min, ERROR_ROUTER_Y_OUT_LESSTHAN_EXPECTED);
        
        // 进行实际交换
        let token_x = Account::withdraw<X>(signer, amount_x_in);
        let (token_x_out, token_y_out);

        if (order == 1) {
            (token_x_out, token_y_out) = TokenPair::swap<X, Y>(token_x, y_out, Token::zero(), 0);
        } else {
            (token_y_out, token_x_out) = TokenPair::swap<Y, X>(Token::zero(), 0, token_x, y_out);
        };
        Token::destroy_zero(token_x_out);
        Account::deposit(Signer::address_of(signer), token_y_out);
    }

    //指定卖出代币数量，得到另一种代币
    public fun swap_token_for_exact_token<X: store, Y: store>(
        signer: &signer,
        amount_x_in_max: u128,
        amount_y_out: u128,
    ) {
        // auto accept
        swap_pair_token_auto_accept<X>(signer);
        let order = TokenPair::compare_token<X, Y>();
        assert(order != 0, ERROR_ROUTER_INVALID_TOKEN_PAIR);

        // 计算输出的y
        let (reserve_x, reserve_y) = get_reserves<X, Y>();

        let x_in = get_amount_in(amount_y_out, reserve_x, reserve_y);
        assert(x_in <= amount_x_in_max, ERROR_ROUTER_X_IN_OVER_LIMIT_MAX);

        // 进行实际交换
        let token_x = Account::withdraw<X>(signer, x_in);
        let (token_x_out, token_y_out);
        if (order == 1) {
            (token_x_out, token_y_out) = TokenPair::swap<X, Y>(token_x, amount_y_out, Token::zero(), 0);
        } else {
            (token_y_out, token_x_out) = TokenPair::swap<Y, X>(Token::zero(), 0, token_x, amount_y_out);
        };
        Token::destroy_zero(token_x_out);
        Account::deposit(Signer::address_of(signer), token_y_out);
    }

    // 获取x，y
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

    // Swap token auto accept
    public fun swap_pair_token_auto_accept<Token: store>(signer: &signer) {
        if (!Account::is_accepts_token<Token>(Signer::address_of(signer))) {
            Account::do_accept_token<Token>(signer);
        };
    }


    public fun get_amount_out(amount_in: u128, reserve_in: u128, reserve_out: u128): u128 {
        assert(amount_in > 0, ERROR_ROUTER_PARAMETER_INVLID);
        assert(reserve_in > 0 && reserve_out > 0, ERROR_ROUTER_PARAMETER_INVLID);

        let amount_in_with_fee = amount_in * 997;
        let numerator = amount_in_with_fee * reserve_out;
        let denominator = reserve_in * 1000 + amount_in_with_fee;
        numerator / denominator
    }

    public fun get_amount_in(amount_out: u128, reserve_in: u128, reserve_out: u128): u128 {
        assert(amount_out > 0, ERROR_ROUTER_PARAMETER_INVLID);
        assert(reserve_in > 0 && reserve_out > 0, ERROR_ROUTER_PARAMETER_INVLID);

        let numerator = reserve_in * amount_out * 1000;
        let denominator = (reserve_out - amount_out) * 997;
        numerator / denominator + 1
    }

}
}