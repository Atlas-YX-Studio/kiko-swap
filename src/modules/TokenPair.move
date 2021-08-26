address 0x100 {
module TokenPair {
    use 0x1::Token;
    use 0x1::Event;

    // token pair pool
    struct TokenPair<X, Y> has key, store  {
        reserve_x: Token::Token<X>,
        reserve_y: Token::Token<Y>,
        block_timestamp_last: u64,
        price_x_cumulative_last: u128,
        price_y_cumulative_last: u128,
        k_last: u128,
        liquidity_event: Event::EventHandle<LiquidityEvent>,
        swap_event: Event::EventHandle<SwapEvent>,
        sync_event: Event::EventHandle<SyncEvent>,
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
        // 
        to: address,
    }

    // event emiited when sync reserve
    struct SyncEvent has drop, store {
        // token code of X type
        x_token_code: Token::TokenCode,
        // token code of X type
        y_token_code: Token::TokenCode,
        // reserve
        reserve_x: u128,
        reserve_y: u128,
    }

    public fun create_pair<X: store, Y: store>(signer: &signer) {

    }

    public fun mint<X: store, Y: store>(signer: &signer, to: address) : u128 {
        0
    }

    public fun burn<X: store, Y: store>(signer: &signer, to: address) : u128 {
        0
    }
        
    public fun skim<X: store, Y: store>(signer: &signer, to: address) {

    }

    public fun sync<X: store, Y: store>(signer: &signer) {

    }

    public fun swap<X: store, Y: store>(
        x_in: Token::Token<X>,
        y_out: u128,
        y_in: Token::Token<Y>,
        x_out: u128,
    ): (Token::Token<X>, Token::Token<Y>) acquires TokenPair {

        let x_in_value = Token::value(&x_in);
        let y_in_value = Token::value(&y_in);

        assert(x_in_value > 0 || y_in_value > 0, ERROR_SWAP_INSUFFICIENT_OUTPUT_AMOUNT);

        //获取币对池 中资产量
        let (x_reserve, y_reserve) = get_reserves<X, Y>();

        //确保对方想要兑换的数量小于池子中代币的数量
        assert(x_in_value < x_reserve && y_in_value < y_reserve, ERROR_SWAP_INSUFFICIENT_LIQUIDITY);

        //从address中拿到resource可变引用，可对resource进行修改
        let token_pair = borrow_global_mut<TokenPair<X, Y>>(admin_address());



        // 把 x_in 写入 token_pair.reserve_x
        Token::deposit(&mut token_pair.reserve_x, x_in);
        // 把 y_in 写入 token_pair.reserve_y
        Token::deposit(&mut token_pair.reserve_y, y_in);

        // 提现x
        let x_swapped = Token::withdraw(&mut token_pair.reserve_x, x_out);
        // 提现y
        let y_swapped = Token::withdraw(&mut token_pair.reserve_y, y_out);


        {
            //调整后的token余额 = 余额数 * 1000 - 注入量 * 3
            let x_reserve_new = Token::value(&token_pair.reserve_x);
            let y_reserve_new = Token::value(&token_pair.reserve_y);
            let x_adjusted = x_reserve_new * 1000 - x_in_value * 3;
            let y_adjusted = y_reserve_new * 1000 - y_in_value * 3;
            //确保新K系数>=旧系数
            assert(x_adjusted * y_adjusted >= x_reserve * y_reserve * 1000000, ERROR_SWAP_SWAPOUT_CALC_INVALID);
        };

        // 更新 token
        update_token_pair<X,Y>(x_reserve, y_reserve);
        (x_swapped, y_swapped)
    }

    // 计算x，y的token的字节码，比较大小，1表示x>y
    public fun compare_token<X: store, Y: store>(): u8 {
        let x_bytes = BCS::to_bytes<Token::TokenCode>(&Token::token_code<X>());
        let y_bytes = BCS::to_bytes<Token::TokenCode>(&Token::token_code<Y>());
        let ret : u8 = Compare::cmp_bcs_bytes(&x_bytes, &y_bytes);
        ret
    }

    //获得令牌对的备用。
    public fun get_reserves<X: store, Y: store>(): (u128, u128) acquires TokenPair {
        //从address中拿到resource引用
        let token_pair = borrow_global<TokenPair<X, Y>>(admin_address());
        let x_reserve = Token::value(&token_pair.reserve_x);
        let y_reserve = Token::value(&token_pair.reserve_y);
        (x_reserve, y_reserve)
    }

    // TWAP price oracle, include update reserves and, on the first call per block, price accumulators
    fun update_token_pair <X: store, Y: store>(
        x_reserve: u128,
        y_reserve: u128,
    ): () acquires TokenPair{
        let token_pair = borrow_global_mut<TokenPair<X, Y>>(admin_address());
        let x_reserve0 = Token::value(&token_pair.reserve_x);
        let y_reserve0 = Token::value(&token_pair.reserve_y);

        let last_block_timestamp = token_pair.block_timestamp_last;
        let block_timestamp = Timestamp::now_seconds();

        let time_elapsed = (block_timestamp - last_block_timestamp as u128);

        if (time_elapsed > 0 && x_reserve !=0 && y_reserve != 0){
            token_pair.price_x_cumulative_last =  token_pair.price_x_cumulative_last + (y_reserve / x_reserve * time_elapsed);
            token_pair.price_y_cumulative_last =  token_pair.price_y_cumulative_last + (x_reserve / y_reserve * time_elapsed);
        };
        token_pair.block_timestamp_last = block_timestamp;
        // todo emit Sync(reserve0, reserve1); 需要吗
    }   

}
}