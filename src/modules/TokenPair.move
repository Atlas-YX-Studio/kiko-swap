address 0x100 {
module {
    
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
        y_token_code: Token::TokenCode
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
        y_token_code: Token::TokenCode
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
        y_token_code: Token::TokenCode
        // reserve
        reserve_x: u128,
        reserve_y: u128,
    }

    public fun create_pair<X: store, Y: store>(signer: &&signer) {

    }

    public fun mint<X: store, Y: store>(signer: &&signer, to: address) : u128 {
        
    }

    public fun burn<X: store, Y: store>(signer: &&signer, to: address) : u128 {

    }

    public fun swap<X: store, Y: store>(signer: &&signer, amount_x_out: u128, amount_y_out: u128, to: address) {

    }

    public fun skim<X: store, Y: store>(signer: &&signer, to: address) {

    }

    public fun sync<X: store, Y: store>(signer: &&signer) {

    }

}
}