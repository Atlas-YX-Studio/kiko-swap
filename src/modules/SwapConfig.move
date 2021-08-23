address 0x100 {
module SwapConfig {

    struct Config has key, store {
        // admin
        admin: address,
        // deposit fee to
        fee_to: address,
        // fee to lp pool
        lp_fee_rate: u128,
        // fee to treasury
        treasury_fee_rate: u128,
        // fee to token buyback
        buyback_fee_rate: u128,
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

    // update admin
    public fun update_admin(signer: &signer, admin: address) {

    }

}

}