//! account: dummy, 0x2
//! sender:dummy
address dummy = {{dummy}};
module dummy::Dummy {
    use 0x1::Account;
    use 0x1::Token;
    use 0x1::Signer;

    struct USDT has copy, drop, store { }
    struct ETH has copy, drop, store { }

    public fun mint_token<TokenType: store>(account: &signer, amount: u128) {
        let is_accept_token = Account::is_accepts_token<TokenType>(Signer::address_of(account));
        if (!is_accept_token) {
            Account::do_accept_token<TokenType>(account);
        };
        let token = Token::mint<TokenType>(account, amount);
        Account::deposit_to_self(account, token);
    }
}

//! new-transaction
//! sender: dummy
address dummy = {{dummy}};
script {
    use 0x1::Account;
    use 0x1::Token;
    use dummy::Dummy::USDT;
    fun register_token(sender: signer) {
        Token::register_token<USDT>(&sender, 9);
        Account::do_accept_token<USDT>(&sender);
    }
}

//! new-transaction
//! account: config, 0x100
//! sender: config
script {
    use 0x100::SwapConfig;
    // init and update config
    fun init_config(sender: signer) {
        SwapConfig::initialize(
            &sender, @0x101, 20u128, 4u128,
            0u128, 0u128, 0u128, 0u128, 0u128
        );
        let (fee_to, fee_rate, treasury_fee_rate) = SwapConfig::get_fee_config();
        assert(fee_to == @0x101 && fee_rate == 20u128 && treasury_fee_rate == 4u128, 1001);
        SwapConfig::update(
            &sender, @0x102, 30u128, 5u128,
            0u128, 0u128, 0u128, 0u128, 0u128
        );
        (fee_to, fee_rate, treasury_fee_rate) = SwapConfig::get_fee_config();
        assert(fee_to == @0x102 && fee_rate == 30u128 && treasury_fee_rate == 5u128, 1002);
    }
}
// check: "Keep(EXECUTED)"

//! new-transaction
//! account: lp_token, 0x200
//! sender: lp_token
script {
    use 0x1::STC::STC;
    use dummy::Dummy::USDT;
    use 0x300::SwapScripts;
    // init_lp_token
    fun init_lp_token(sender: signer) {
        SwapScripts::init_lp_token<STC, USDT>(sender);
    }
}
// check: "Keep(EXECUTED)"

//! new-transaction
//! account: pair, 0x100
//! sender: pair
script {
    use 0x1::STC::STC;
    use 0x1::DummyToken::DummyToken;
    // use dummy::Dummy::USDT;
    use 0x100::SwapLibrary;
    // use 0x300::SwapScripts;
    // create_pair
    fun create_pair(_sender: signer) {
        let _order = SwapLibrary::get_token_order<STC, DummyToken>();
        // SwapScripts::create_pair<STC, USDT>(sender);
    }
}
// check: EXECUTED