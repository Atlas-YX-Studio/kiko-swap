address 0x100 {
module SwapPair {
    use 0x1::Token;
    use 0x1::Event;
    use 0x1::Signer;
    use 0x100::LPToken;
    use 0x100::SwapConfig;

    const PAIR_ADDRESS = @0x100;

    const PERMISSION_DENIED: u64 = 200001;
    const INSUFFICIENT_LIQUIDITY_MINTED: u64 = 200002;
    const INSUFFICIENT_LIQUIDITY_BURNED: u64 = 200003;

    // token pair pool
    struct SwapPair<X, Y> has key, store {
        // reserve token
        reserve_x_token: Token::Token<X>,
        reserve_y_toekn: Token::Token<Y>,
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
    public fun get_reserves<X: store, Y: store>(): u128, u128 {
        let swap_pair = borrow_global<SwapPair<X, Y>>(PAIR_ADDRESS);
        (swap_pair.reserve_x, swap_pair.reserve_y)
    }

    // create token pair pool
    public fun create_pair<X: store, Y: store>(signer: &signer) {
        assert(Signer::address_of(signer) == PAIR_ADDRESS, PERMISSION_DENIED);
        let swap_pair = SwapPair<X, Y> {
            reserve_x: Token::zero<X>(),
            reserve_y: Token::zero<Y>(),
            block_timestamp_last: 0,
            price_x_cumulative_last: 0,
            price_y_cumulative_last: 0,
            last_k: 0,
            create_pair_event: Event::new_event_handle<CreatePairEvent>(signer),
            liquidity_event: Event::new_event_handle<LiquidityEvent>(signer),
            swap_event: Event::new_event_handle<SwapEvent>(signer),
        }
        move_to(signer, swap_pair);
        Event::emit_event(&mut swap_pair.create_pair_event,
            CreatePairEvent {
                signer: Signer::address_of(signer),
                y_token_code: Token::token_code<Y>(),
                x_token_code: Token::token_code<X>(),
                block_timestamp_last: Timestamp::now_milliseconds();
            });
    }

    // update reserve amount and block timestamp
    fun _update<X: store, Y: store>(
        balance_x: u128,
        balance_y: u128,
        swap_pair: &mut SwapPair<X, Y>,
    ) () {
        swap_pair.reserve_x = balance_x;
        swap_pair.reserve_y = balance_y;
        swap_pair.last_block_timestamp = Timestamp::now_milliseconds();
    }

    // mint fee to platform
    fun _mint_fee<X: store, Y: store>(
        swap_pair: &mut SwapPair<X, Y>,
        _total_supply: u128
    ): bool {
        let _reserve_x = swap_pair.reserve_x;
        let _reserve_y = swap_pair.reserve_y;
        let _k_last = swap_pair.k_last;
        let (fee_to, fee_rate, treasury_fee_rate = SwapConfig::get_fee_config();
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
        let swap_pair = borrow_global_mut<SwapPair<X, Y>>(PAIR_ADDRESS);
        let balance_x = Token::value<X>(&swap_pair.reserve_x_token);
        let balance_y = Token::value<Y>(&swap_pair.reserve_y_token);
        let total_supply = Token::market_cap<LiquidityToken<X, Y>>();

        let fee_on = _mint_fee<X, Y>(&mut swap_pair, total_supply);
        let liquidity: u128;
        if (total_supply == 0) {
            liquidity = Math::sqrt(amount_x * amount_y);
        } else {
            let liquidity_x = amount_x * total_supply / swap_pair.reserve_x;
            let liquidity_y = amount_y * total_supply / swap_pair.reserve_y;
            if (liquidity_x < liquidity_y>) {
                liquidity = liquidity_x
            } else {
                liquidity = liquidity_y
            };
        };
        assert(liquidity > 0, INSUFFICIENT_LIQUIDITY_MINTED);
        LPToken::mint_to(signer, liquidity);

        _update<X, Y>(balance_x, balance_y, swap_pair);
        if (fee_on) {
            swap_pair.k_last = balance_x * balance_y;
        };
    }

    // transfer token and emit event
    public fun add_liquidity<X: store, Y: store>(
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
        // mint LP token to user
        mint(signer, amount_x, amount_y);

        Event::emit_event(&mut swap_pair.liquidity_event,
            LiquidityEvent {
                signer: Signer::address_of(signer),
                x_token_code: Token::token_code<X>(),
                y_token_code: Token::token_code<Y>(),
                direction: 1,
                amount_x: amount_x,
                amount_y: amount_y,
                reserve_amount_x: swap_pair.reserve_x,
                reserve_amount_y: swap_pair.reserve_y,
                block_timestamp_last: swap_pair.block_timestamp_last;
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
        bool fee_on = _mint_fee<X, Y>(swap_pair);
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
        _update<X, Y>(balance_x, balance_y, swap_pair);
        if (fee_on) {
            swap_pair.k_last = balance_x * balance_y;
        };
        return (amount_x, amount_y)
    }

    // remove liquidity and emit event
    public fun remove_liquidity<X: store, Y: store>(
        &signer: &&signer, 
        liquidity: u128
    ): (u128, u128) {
        let (amount_x, amount_y) = SwapPair::burn<X, Y>(signer, liquidity);        

        Event::emit_event(&mut swap_pair.liquidity_event,
            LiquidityEvent {
                signer: Signer::address_of(signer),
                x_token_code: Token::token_code<X>(),
                y_token_code: Token::token_code<Y>(),
                direction: 0,
                amount_x: amount_x,
                amount_y: amount_y,
                reserve_amount_x: swap_pair.reserve_x,
                reserve_amount_y: swap_pair.reserve_y,
                block_timestamp_last: swap_pair.block_timestamp_last;
            });
        return (amount_x, amount_y)
    }

    // swap token
    public fun swap<X: store, Y: store>(
        x_in: Token::Token<X>,
        y_out: u128,
        y_in: Token::Token<Y>,
        x_out: u128
    ): (Token::Token<X>, Token::Token<Y>) acquires SwapPair {
        
        let x_in_value = Token::value(&x_in);
        let y_in_value = Token::value(&y_in);
        assert(x_in_value > 0 || y_in_value > 0, ERROR_SWAP_INSUFFICIENT_OUTPUT_AMOUNT);
        
        let (x_reserve, y_reserve) = get_reserves<X, Y>();
        assert(x_in_value < x_reserve && y_in_value < y_reserve, ERROR_SWAP_INSUFFICIENT_LIQUIDITY);
    
       let swap_pair = borrow_global_mut<SwapPair<X, Y>>(PAIR_ADDRESS);

        Token::deposit(&mut swap_pair.reserve_x, x_in);
        Token::deposit(&mut swap_pair.reserve_y, y_in);
        // transfer token to pair
        let x_swapped = Token::withdraw(&mut swap_pair.reserve_x, x_out);
        let y_swapped = Token::withdraw(&mut swap_pair.reserve_y, y_out);

        {
            let x_reserve_new = Token::value(&swap_pair.reserve_x);
            let y_reserve_new = Token::value(&swap_pair.reserve_y);
            let x_adjusted = x_reserve_new * 1000 - x_in_value * 3;
            let y_adjusted = y_reserve_new * 1000 - y_in_value * 3;
            assert(x_adjusted * y_adjusted >= x_reserve * y_reserve * 1000000, ERROR_SWAP_SWAPOUT_CALC_INVALID);
        };
        _update<X,Y>(x_reserve, y_reserve);
        (x_swapped, y_swapped)
    }

    public fun skim<X: store, Y: store>(signer: &signer) {

    }

    public fun sync<X: store, Y: store>(signer: &signer) {

    }
}

module SwapPairScripts{
    use 0x100::SwapPair;

    public(script) fun create_pair<X: store, Y: store>(sender: signer) {
        SwapPair::create_pair<X, Y>(&sender);
    }
}
}