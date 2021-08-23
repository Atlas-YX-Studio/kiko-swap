address 0x100 {
module LPToken {
    use 0x1::Token::{Self, Token};

    struct LPToken<X, Y> has key, store { }

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
    public fun mint<X: store, Y: store>(_account: &signer, amount: u128): Token<LPToken<X, Y>> acquires SharedMintCapability{
        let cap = borrow_global<SharedMintCapability<X, Y>>(token_address<X, Y>());
        Token::mint_with_capability(&cap.cap, amount)
    }

    /// Return the token address.
    public fun token_address<X: store, Y: store>(): address {
        Token::token_address<LPToken<X, Y>>()
    }
}

module LPTokenScripts{
    use 0x100::LPToken::{Self,LPToken};
    use 0x1::Account;
    use 0x1::Signer;

    public(script) fun initialize<X: store, Y: store>(sender: signer) {
        LPToken::initialize<X, Y>(&sender);
    }

    public(script) fun mint<X: store, Y: store>(sender: signer, amount: u128){
        let token = LPToken::mint<X, Y>(&sender, amount);
        let sender_addr = Signer::address_of(&sender);
        if(Account::is_accept_token<LPToken<X, Y>>(sender_addr)){
            Account::do_accept_token<LPToken<X, Y>>(&sender);
        };
        Account::deposit(sender_addr, token);
    }
}

}