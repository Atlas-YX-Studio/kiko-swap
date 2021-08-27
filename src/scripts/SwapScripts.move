address 0x200 {
module SwapScripts {
use 0x100::LPToken;
use 0x100::SwapConfig;
use 0x100::SwapPair;
use 0x100::SwapRouter;

    // init config only once
    public(script) fun init_config(
        sender: signer,
        fee_to: address,
        fee_rate: u128,
        treasury_fee_rate: u128,
        extra0: u128,
        extra1: u128,
        extra2: u128,
        extra3: u128,
        extra4: u128,
    ) {
        SwapConfig::initialize(
            &sender, 
            fee_to, 
            fee_rate, 
            treasury_fee_rate,
            extra0, 
            extra1, 
            extra2, 
            extra3, 
            extra4
        );
    }

    // update config
    public(script) fun update_config(
        signer: &signer,
        fee_to: address,
        fee_rate: u128,
        treasury_fee_rate: u128,
        extra0: u128,
        extra1: u128,
        extra2: u128,
        extra3: u128,
        extra4: u128,
    ) {
        SwapConfig::update(
            &sender, 
            fee_to, 
            fee_rate, 
            treasury_fee_rate,
            extra0, 
            extra1, 
            extra2, 
            extra3, 
            extra4
        );
    }

    public(script) fun init_lp_token<X: store, Y: store>(sender: signer) {
        LPToken::initialize<X, Y>(&sender);
    }

    public(script) fun create_pair<X: store, Y: store>(sender: signer) {
        SwapPair::create_pair<X, Y>(&sender);
    }

    public(script) fun add_liquidity<X: store, Y: store>(
        sender: signer,
        amount_x_desired: u128,
        amount_y_desired: u128,
        amount_x_min: u128,
        amount_y_min: u128
    ) {
        SwapRouter::add_liquidity<X, Y>(
            &sender,
            amount_x_desired,
            amount_y_desired,
            amount_x_min,
            amount_y_min
        );
    }

    public(script) fun remove_liquidity<X: store, Y: store>(
        sender: signer,
        liquidity: u128,
        amount_x_min: u128,
        amount_y_min: u128
    ) {
        SwapRouter::remove_liquidity<X, Y>(
            &sender,
            liquidity,
            amount_x_min,
            amount_y_min
        );
    }

    public(script) fun swap_exact_token_for_token<X: store, Y: store>(
        sender: signer,
        amount_x_in: u128,
        amount_y_out_min: u128
    ) {
        SwapRouter::swap_exact_token_for_token<X, Y>(
            &sender,
            amount_x_in,
            amount_y_out_min
        );
    }

    public(script) fun swap_token_for_exact_token<X: store, Y: store>(
        sender: signer,
        amount_x_in_max: u128,
        amount_y_out: u128
    ) {
        SwapRouter::swap_token_for_exact_token<X, Y>(
            &sender,
            amount_x_in_max,
            amount_y_out
        );
    }

}
}