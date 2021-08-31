//! account: dummy, 0x2
//! sender:dummy
address dummy = {{dummy}};
module dummy::Dummy {
    use 0x1::Account;
    use 0x1::Token;
    use 0x1::Signer;

    struct USDT has copy, drop, store { }
    struct ETH has copy, drop, store { }

    struct SharedMintCapability<TokenType: store> has key, store {
        cap: Token::MintCapability<TokenType>,
    }

    struct SharedBurnCapability<TokenType> has key {
        cap: Token::BurnCapability<TokenType>,
    }

    public fun initialize<TokenType: store>(account: &signer) {
        Token::register_token<TokenType>(account, 9);
        Account::do_accept_token<TokenType>(account);
        let burn_cap = Token::remove_burn_capability<TokenType>(account);
        move_to(account, SharedBurnCapability<TokenType> { cap: burn_cap });
        let mint_cap = Token::remove_mint_capability<TokenType>(account);
        move_to(account, SharedMintCapability<TokenType> { cap: mint_cap });
    }

    public fun mint_token<TokenType: store>(account: &signer, amount: u128) acquires SharedMintCapability {
        let is_accept_token = Account::is_accepts_token<TokenType>(Signer::address_of(account));
        if (!is_accept_token) {
            Account::do_accept_token<TokenType>(account);
        };
        let token = mint<TokenType>(amount);
        Account::deposit_to_self(account, token);
    }

    /// Burn the given token.
    public fun burn<TokenType: store>(token: Token::Token<TokenType>) acquires SharedBurnCapability{
        let cap = borrow_global<SharedBurnCapability<TokenType>>(token_address<TokenType>());
        Token::burn_with_capability(&cap.cap, token);
    }

    public fun mint<TokenType: store>(amount: u128): Token::Token<TokenType> acquires SharedMintCapability {
        let cap = borrow_global<SharedMintCapability<TokenType>>(token_address<TokenType>());
        Token::mint_with_capability<TokenType>(&cap.cap, amount)
    }

    public fun token_address<TokenType: store>(): address {
        Token::token_address<TokenType>()
    }
}
// check: "Keep(EXECUTED)"

//! new-transaction
//! sender: dummy
script {
    use 0x1::Account;
    use 0x1::Debug;
    use dummy::Dummy::{Self, USDT};

    const MULTIPLE: u128 = 1000000000;

    fun register_token(sender: signer) {
        Dummy::initialize<USDT>(&sender);
        Dummy::mint_token<USDT>(&sender, 1 * MULTIPLE);
        Debug::print<u128>(&Account::balance<USDT>(@dummy));
    }
}
// check: "Keep(EXECUTED)"


//! new-transaction
//! account: admin, 0x100
//! sender: admin
script {
    use 0x100::SwapConfig;
    // init and update config
    fun init_config(sender: signer) {
        SwapConfig::initialize(
            &sender, 20u128, 4u128,
            0u128, 0u128, 0u128, 0u128, 0u128
        );
        let (fee_rate, treasury_fee_rate) = SwapConfig::get_fee_config();
        assert(fee_rate == 20u128 && treasury_fee_rate == 4u128, 1001);
        SwapConfig::update(
            &sender, 30u128, 5u128,
            0u128, 0u128, 0u128, 0u128, 0u128
        );
        (fee_rate, treasury_fee_rate) = SwapConfig::get_fee_config();
        assert(fee_rate == 30u128 && treasury_fee_rate == 5u128, 1002);
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
//! sender: admin
address admin = {{admin}};
script {
    use 0x1::STC::STC;
    use dummy::Dummy::USDT;
    use 0x100::SwapPair;
    use 0x300::SwapScripts;
    // create_pair
    fun create_pair(sender: signer) {
        SwapScripts::create_pair<STC, USDT>(sender);
        assert(SwapPair::pair_exists<STC, USDT>(@admin), 3001);
    }
}
// check: EXECUTED

//! new-transaction
//! account: lp, 20000000000 0x1::STC::STC
//! sender: lp
address lp = {{lp}};
script {
    use 0x1::Account;
    use 0x1::Debug;
    use 0x1::STC::STC;
    use dummy::Dummy::{Self, USDT};
    use 0x200::LPToken::LPToken;
    use 0x300::SwapScripts;

    const MULTIPLE: u128 = 1000000000;

    // add_liquidity, STC:USDT = 5:20 = 1:4, k = 100, lptoken = 5
    fun add_liquidity(sender: signer) {
        Dummy::mint_token<USDT>(&sender, 20 * MULTIPLE);
        SwapScripts::add_liquidity<STC, USDT>(sender, 5*MULTIPLE , 20*MULTIPLE, 1*MULTIPLE, 10*MULTIPLE);
        // get 5 LP token
        Debug::print<u128>(&Account::balance<LPToken<STC, USDT>>(@lp));
    }
}


