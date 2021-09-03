//! account: dummy, 0x2
//! sender:dummy
address dummy = {{dummy}};
module dummy::Dummy {
    use 0x1::Account;
    use 0x1::Token;

    struct ETH has copy, drop, store { }
    struct USDT has copy, drop, store { }

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
    use dummy::Dummy::{Self, ETH, USDT};

    const MULTIPLE: u128 = 1000000000;

    fun register_token(sender: signer) {
        Dummy::initialize<ETH>(&sender);
        Dummy::initialize<USDT>(&sender);
    }
}
// check: "Keep(EXECUTED)"

//! new-transaction
//! account: admin, 0x100
//! sender: admin
address admin = {{admin}};
script {
    use dummy::Dummy::{ETH, USDT};
    use 0x100::SwapConfig;
    use 0x100::SwapPair;
    use 0x300::SwapScripts;
    // init config and pair
    fun init(sender: signer) {
        SwapConfig::initialize(
            &sender, 20u128, 4u128,
            0u128, 0u128, 0u128, 0u128, 0u128
        );
        SwapConfig::update(
            &sender, 30u128, 5u128,
            0u128, 0u128, 0u128, 0u128, 0u128
        );
        let (fee_rate, treasury_fee_rate) = SwapConfig::get_fee_config();
        assert(fee_rate == 30u128 && treasury_fee_rate == 5u128, 3002);
        // create pair
        SwapScripts::create_pair<ETH, USDT>(sender);
        assert(SwapPair::pair_exists<ETH, USDT>(@admin), 3003);
    }
}
// check: "Keep(EXECUTED)"

//! new-transaction
//! account: lp, 10000000000 0x1::STC::STC
//! sender: lp
address lp = {{lp}};
script {
    use dummy::Dummy::{Self, ETH, USDT};
    use 0x300::SwapScripts;
    use 0x100::SwapPair;
    use 0x1::Debug;
    const MULTIPLE: u128 = 1000000000;

    // add_liquidity, STC:USDT = 5:20 = 1:4, k = 100, lptoken = 5
    fun add_liquidity(sender: signer) {
        Dummy::mint_token<ETH>(&sender, 50 * MULTIPLE * MULTIPLE);
        Dummy::mint_token<USDT>(&sender, 200 * MULTIPLE * MULTIPLE);
        SwapScripts::add_liquidity<ETH, USDT>(sender, 50 * MULTIPLE * MULTIPLE , 200 * MULTIPLE * MULTIPLE, 1 * MULTIPLE * MULTIPLE, 1 * MULTIPLE * MULTIPLE);


        let (reserve_x, reserve_y) = SwapPair::get_reserves<ETH, USDT>();

        Debug::print<u128>(&reserve_x);
        Debug::print<u128>(&reserve_y);
    }
}
// check: EXECUTED
