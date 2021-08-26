address 0x100 {
module LPToken {
    use 0x1::Token::{Self, Token};

    struct LPToken<X, Y> has key, store {}

    const PRECISION: u8 = 9;

    /// Burn capability of the token.
    struct SharedBurnCapability<X, Y> has key {
        cap: Token::BurnCapability<LPToken<X, Y>>,
    }

    /// Mint capability of the token.
    struct SharedMintCapability<X, Y>  has key, store {
        cap: Token::MintCapability<LPToken<X, Y>>,
    }

    /// Initialization of the module.
    public fun initialize<X: store, Y: store>(account: &signer) {
        Token::register_token<LPToken<X, Y>>(
            account,
            PRECISION,
        );

        let burn_cap = Token::remove_burn_capability<LPToken<X, Y>>(account);
        move_to(account, SharedBurnCapability{cap: burn_cap});

        let burn_cap = Token::remove_mint_capability<LPToken<X, Y>>(account);
        move_to(account, SharedMintCapability{cap: burn_cap});
    }

    /// Burn the given token.
    public fun burn<X: store, Y: store>(token: Token<LPToken<X, Y>>) acquires SharedBurnCapability{
        let cap = borrow_global<SharedBurnCapability<X, Y>>(token_address<X, Y>());
        Token::burn_with_capability(&cap.cap, token);
    }

    /// Anyone can mint LPToken<X, Y>
    public fun mint<X: store, Y: store>(amount: u128): Token<LPToken<X, Y>> acquires SharedMintCapability{
        let cap = borrow_global<SharedMintCapability<X, Y>>(token_address<X, Y>());
        Token::mint_with_capability(&cap.cap, amount)
    }

    /// Mint token to singer
    public fun mint_to<X: store, Y: store>(account: signer, amount: u128): Token<LPToken<X, Y>> acquires SharedMintCapability{
        let is_accept_token = Account::is_accepts_token<LPToken<X, Y>>(Signer::address_of(&account));
        if (!is_accept_token) {
            Account::do_accept_token<LPToken<X, Y>>(&account);
        };
        let token = mint<LPToken<X, Y>>(amount);
        Account::deposit_to_self(&account, token);
    }

    /// Return the token address.
    public fun token_address<X: store, Y: store>(): address {
        Token::token_address<LPToken<X, Y>>()
    }
}

module LPTokenScripts{
    use 0x100::LPToken;

    public(script) fun initialize<X: store, Y: store>(sender: signer) {
        LPToken::initialize<X, Y>(&sender);
    }
}
}