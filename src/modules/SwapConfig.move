address 0x100 {
module SwapConfig {

    const CONFIG_ADDRESS: address = @0x100;

    struct Config has key, store {
        // deposit fee to
        fee_to: address,
        // total fee, 30 for 0.3%
        fee_rate: u128,
        // fee ratio to treasury, 5 for 0.05%
        treasury_fee_rate: u128,
        // extra config
        extra0: u128,
        extra1: u128,
        extra2: u128,
        extra3: u128,
        extra4: u128,
    }

    // init
    public fun init() {
        
    }

    // update
    public fun update() {
        
    }

    public fun get_fee_config(): (address, u128, u128) acquires Config {
        let config = borrow_global<Config>(CONFIG_ADDRESS);
        (config.fee_to, config.fee_rate, config.treasury_fee_rate)
    }

}

}