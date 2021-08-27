address 0x100 {
module SwapPair {
    use 0x1::Token;
    use 0x1::Event;
    use 0x1::Signer;
    use 0x1::Account;
    use 0x1::Math;
    use 0x1::Timestamp;
    use 0x100::LPToken;
    use 0x100::SwapConfig;
    use 0x100::LPToken;

    const PAIR_ADDRESS: address = @0x100;

    const PERMISSION_DENIED: u64 = 200001;
    const INSUFFICIENT_LIQUIDITY_MINTED: u64 = 200002;
    const INSUFFICIENT_LIQUIDITY_BURNED: u64 = 200003;
    const INSUFFICIENT_OUTPUT_AMOUNT: u64 = 200004;
    const INSUFFICIENT_INPUT_AMOUNT: u64 = 200005;
    const INSUFFICIENT_LIQUIDITY: u64 = 200006;
    const INVALID_K: u64 = 200007;

    // token pair pool
    struct SwapPair<X, Y> has key, store {
        // reserve token
        reserve_x_token: Token::Token<X>,
        reserve_y_token: Token::Token<Y>,
        // token amount
        reserve_x: u128,
        reserve_y: u128,
        // last k
        k_last: u128,
        // last update timestamp
        block_timestamp_last: u64,
        // event
        create_pair_event: Event::EventHandle<CreatePairEvent>,
        liquidity_event: Event::EventHandle<LiquidityEvent>,
        swap_event: Event::EventHandle<SwapEvent>,
    }

    // event emitted when create lp pool
    struct CreatePairEvent has drop, store {
        signer: address,
         // token code of X type
        x_token_code: Token::TokenCode,
        // token code of X type
        y_token_code: Token::TokenCode,
        // last update timestamp
        block_timestamp_last: u64,
    }

    // event emitted when update liquidity
    struct LiquidityEvent has drop, store {
        signer: address,
         // token code of X type
        x_token_code: Token::TokenCode,
        // token code of X type
        y_token_code: Token::TokenCode,
        // 0 for remove, 1 for add
        direction: u8,
        // amount of x and y
        amount_x: u128,
        amount_y: u128,
        // reserve of x and y
        reserve_x: u128,
        reserve_y: u128,
        // last update timestamp
        block_timestamp_last: u64,
    }

    // event emiited when swap token
    struct SwapEvent has drop, store {
        signer: address,
         // token code of X type
        x_token_code: Token::TokenCode,
        // token code of X type
        y_token_code: Token::TokenCode,
        // amount in
        amount_x_in: u128,
        amount_y_in: u128,
        // amount out
        amount_x_out: u128,
        amount_y_out: u128,
        // reserve of x and y
        reserve_x: u128,
        reserve_y: u128,
        // last update timestamp
        block_timestamp_last: u64,
    }

    // fetches and sorts the reserves for a pair
    public fun get_reserves<X: store, Y: store>(): (u128, u128) {
        let swap_pair = borrow_global<SwapPair<X, Y>>(PAIR_ADDRESS);
        (swap_pair.reserve_x, swap_pair.reserve_y)
    }

    // create token pair pool
    public fun create_pair<X: store, Y: store>(signer: &signer) {
        assert(Signer::address_of(signer) == PAIR_ADDRESS, PERMISSION_DENIED);
        let swap_pair = SwapPair<X, Y> {
            reserve_x_token: Token::zero<X>(),
            reserve_y_token: Token::zero<Y>(),
            reserve_x: 0u128,
            reserve_y: 0u128,
            k_last: 0u128,
            block_timestamp_last: 0,
            create_pair_event: Event::new_event_handle<CreatePairEvent>(signer),
            liquidity_event: Event::new_event_handle<LiquidityEvent>(signer),
            swap_event: Event::new_event_handle<SwapEvent>(signer)
        };
        move_to<SwapPair<X, Y>>(signer, swap_pair); 

        Event::emit_event(&mut swap_pair.create_pair_event,
            CreatePairEvent {
                signer: Signer::address_of(signer),
                y_token_code: Token::token_code<Y>(),
                x_token_code: Token::token_code<X>(),
                block_timestamp_last: Timestamp::now_milliseconds()
            });
    }

    // update reserve amount and block timestamp
    fun f_update<X: store, Y: store>(
        balance_x: u128,
        balance_y: u128,
        swap_pair: &mut SwapPair<X, Y>
    ){
        swap_pair.reserve_x = balance_x;
        swap_pair.reserve_y = balance_y;
        swap_pair.block_timestamp_last = Timestamp::now_milliseconds();
    }

    // mint fee to platform
    fun f_mint_fee<X: store, Y: store>(
        swap_pair: &mut SwapPair<X, Y>,
        _total_supply: u128
    ): bool {
        let _reserve_x = swap_pair.reserve_x;
        let _reserve_y = swap_pair.reserve_y;
        let _k_last = swap_pair.k_last;
        let (fee_to, fee_rate, treasury_fee_rate) = SwapConfig::get_fee_config();
        let fee_on = (fee_to != @0x1 && treasury_fee_rate > 0 && fee_rate > treasury_fee_rate);
        if (fee_on) {
            if (_k_last != 0) {
                let root_k = Math::sqrt(_reserve_x * _reserve_y);
                let root_k_last = Math::sqrt(_k_last);
                if (root_k > root_k_last) {
                    let numerator = _total_supply * (root_k - root_k_last);
                    let denominator = (fee_rate / treasury_fee_rate - 1) * root_k + root_k_last;
                    let liquidity = numerator / denominator;
                    if (liquidity > 0) {
                        LPToken::mint_to<X, Y>(signer, liquidity);
                    }
                }
            }
        } else {
            if (_k_last != 0) {
                swap_pair.k_last = 0;
            };
        };
        return fee_on
    }

    // mint LP token to user and platform
    fun mint<X: store, Y: store>(
        signer: &signer,
        amount_x: u128,
        amount_y: u128
    ) {
        // transfer token to pair
        let x_token = Account::withdraw<X>(signer, amount_x);
        let y_token = Account::withdraw<Y>(signer, amount_y);
        let swap_pair = borrow_global_mut<SwapPair<X, Y>>(PAIR_ADDRESS);
        Token::deposit(&mut swap_pair.reserve_x_token, x_token);
        Token::deposit(&mut swap_pair.reserve_y_token, y_token);
        
        let swap_pair = borrow_global_mut<SwapPair<X, Y>>(PAIR_ADDRESS);
        let balance_x = Token::value<X>(&swap_pair.reserve_x_token);
        let balance_y = Token::value<Y>(&swap_pair.reserve_y_token);
        let total_supply = Token::market_cap<SwapPair<X, Y>>();
        // mint LP token to platform
        let fee_on = f_mint_fee<X, Y>(&mut swap_pair, total_supply);
        // mint LP token to user
        let liquidity: u128;
        if (total_supply == 0) {
            liquidity = Math::sqrt(amount_x * amount_y);
        } else {
            let liquidity_x = amount_x * total_supply / swap_pair.reserve_x;
            let liquidity_y = amount_y * total_supply / swap_pair.reserve_y;
            if (liquidity_x < liquidity_y) {
                liquidity = liquidity_x
            } else {
                liquidity = liquidity_y
            };
        };
        assert(liquidity > 0, INSUFFICIENT_LIQUIDITY_MINTED);
        LPToken::mint_to(signer, liquidity);

        f_update<X, Y>(balance_x, balance_y, swap_pair);
        if (fee_on) {
            swap_pair.k_last = balance_x * balance_y;
        };
        Event::emit_event(&mut swap_pair.liquidity_event,
            LiquidityEvent {
                signer: Signer::address_of(signer),
                x_token_code: Token::token_code<X>(),
                y_token_code: Token::token_code<Y>(),
                direction: 1,
                amount_x: amount_x,
                amount_y: amount_y,
                reserve_x: swap_pair.reserve_x,
                reserve_y: swap_pair.reserve_y,
                block_timestamp_last: swap_pair.block_timestamp_last
            });
    }

    // burn LP token and obtain x and y
    public fun burn<X: store, Y: store>(
        signer: &signer, 
        liquidity: u128
    ): (u128, u128) {
        let liquidity_token = Account::withdraw<LPToken<X, Y>>(signer, liquidity);

        let swap_pair = borrow_global_mut<SwapPair<X, Y>>(PAIR_ADDRESS);
        let balance_x = Token::value<X>(&swap_pair.reserve_x_token);
        let balance_y = Token::value<Y>(&swap_pair.reserve_y_token);
        let total_supply = Token::market_cap<LPToken<X, Y>>();
        // mint LP token to platform
        let fee_on = f_mint_fee<X, Y>(swap_pair, total_supply);
        let amount_x = liquidity * balance_x / total_supply;
        let amount_y = liquidity * balance_y / total_supply;
        assert(amount_x > 0 && amount_y > 0, INSUFFICIENT_LIQUIDITY_BURNED);
        // burn LP token
        LPToken::burn<X, Y>(signer, liquidity_token);
        // obtain x and y
        let x_token = Token::withdraw<X>(&swap_pair.reserve_x_token);
        let y_token = Token::withdraw<Y>(&swap_pair.reserve_y_token);
        let signer_address = Signer::address_of(signer);
        Account::deposit<X>(signer_address, x_token);
        Account::deposit<Y>(signer_address, y_token);
        f_update<X, Y>(balance_x, balance_y, swap_pair);
        if (fee_on) {
            swap_pair.k_last = balance_x * balance_y;
        };

        Event::emit_event(&mut swap_pair.liquidity_event,
            LiquidityEvent {
                signer: Signer::address_of(signer),
                x_token_code: Token::token_code<X>(),
                y_token_code: Token::token_code<Y>(),
                direction: 0,
                amount_x: amount_x,
                amount_y: amount_y,
                reserve_x: swap_pair.reserve_x,
                reserve_y: swap_pair.reserve_y,
                block_timestamp_last: swap_pair.block_timestamp_last
            });
        return (amount_x, amount_y)
    }

    // swap x and y
    public fun swap<X: store, Y: store>(
        signer: &signer,
        amount_x_in: u128,
        amount_y_in: u128,
        amount_x_out: u128,
        amount_y_out: u128
    ) {
        // transfer token_in to pair
        assert(amount_x_in > 0 || amount_y_in > 0, INSUFFICIENT_INPUT_AMOUNT);
        let swap_pair = borrow_global_mut<SwapPair<X, Y>>(PAIR_ADDRESS);
        if (amount_x_in > 0) {
            let x_in_token = Account::withdraw<X>(signer, amount_x_in);
            Token::deposit(&mut swap_pair.reserve_x_token, x_in_token);
        };
        if (amount_y_in > 0) {
            let y_in_token = Account::withdraw<Y>(signer, amount_y_in);
            Token::deposit(&mut swap_pair.reserve_y_token, y_in_token);
        };
        // transfer token_out to user
        assert(amount_x_out > 0 || amount_y_out > 0, INSUFFICIENT_OUTPUT_AMOUNT);
        let _reserve_x = swap_pair.reserve_x;
        let _reserve_y = swap_pair.reserve_y;
        assert(amount_x_out < _reserve_x && amount_y_out < _reserve_y, INSUFFICIENT_LIQUIDITY);
        if (amount_x_out > 0) {
            let x_out_token = Token::withdraw<X>(&mut swap_pair.reserve_x_token, amount_x_out);
            Account::deposit<X>(signer_address, x_out_token);
        };
        if (amount_y_out > 0) {
            let y_out_token = Token::withdraw<Y>(&mut swap_pair.reserve_y_token, amount_y_out);
            Account::deposit<Y>(signer_address, y_out_token);
        };
        // check k
        let balance_x = Token::value<X>(&swap_pair.reserve_x);
        let balance_y = Token::value<Y>(&swap_pair.reserve_y);
        let (_, fee_rate, _) = SwapConfig::get_fee_config();
        let balance_x_adjusted = balance_x * 10000 - amount_x_in * fee_rate;
        let balance_y_adjusted = balance_y * 10000 - amount_y_in * fee_rate;
        assert(balance_x_adjusted * balance_y_adjusted >= x_reserve * y_reserve * 100000000, INVALID_K);
        // update reserve
        f_update<X, Y>(balance_x, balance_y, swap_pair);
        // emit event
        Event::emit_event(&mut swap_pair.swap_event,
            SwapEvent {
                signer: Signer::address_of(signer),
                x_token_code: Token::token_code<X>(),
                y_token_code: Token::token_code<Y>(),
                amount_x_in: amount_x_in,
                amount_y_in: amount_y_in,
                amount_x_out: amount_x_out,
                amount_y_out: amount_y_out,
                reserve_x: balance_x,
                reserve_y: balance_y,
                block_timestamp_last: swap_pair.block_timestamp_last
            });
    }

}
}