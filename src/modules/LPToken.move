address 0x100 {
module LPToken {
    use 0x1::Token::{Self, Token};
    use 0x1::Errors;

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
    public fun initialize<TokenType: store>(account: &signer) {
        Token::register_token<LPToken<X, Y>>(
            account,
            PRECISION,
        );

        let burn_cap = Token::remove_burn_capability<LPToken<X, Y>>(account);
        move_to(account, SharedBurnCapability{cap: burn_cap});

        let burn_cap = Token::remove_mint_capability<LPToken<X, Y>>(account);
        move_to(account, SharedMintCapability{cap: burn_cap});
    }

    /// Returns true if `TokenType` is `LPToken::LPToken<X, Y>`
    public fun is_dummy_token<TokenType: store>(): bool {
        Token::is_same_token<LPToken<X, Y>, TokenType>()
    }

    /// Burn the given token.
    public fun burn(token: Token<LPToken<X, Y>>) acquires SharedBurnCapability{
        let cap = borrow_global<SharedBurnCapability>(token_address());
        Token::burn_with_capability(&cap.cap, token);
    }

    /// Anyone can mint LPToken<X, Y>
    public fun mint(_account: &signer, amount: u128) : Token<LPToken<X, Y>> acquires SharedMintCapability{
        let cap = borrow_global<SharedMintCapability>(token_address());
        Token::mint_with_capability(&cap.cap, amount)
    }

    /// Return the token address.
    public fun token_address(): address {
        Token::token_address<LPToken<X, Y>>()
    }
}

module LPTokenScripts{
    use 0x100::LPToken::{Self,LPToken};
    use 0x1::Account;
    use 0x1::Signer;

    public(script) fun initialize<X: store, Y: store>(sender: signer) {
        LPToken<X, Y>::initialize(&sender);
    }

    public(script) fun mint<X: store, Y: store>(sender: signer, amount: u128){
        let token = LPToken<X, Y>::mint(&sender, amount);
        let sender_addr = Signer::address_of(&sender);
        if(Account::is_accept_token<LPToken<X, Y>>(sender_addr)){
            Account::do_accept_token<LPToken<X, Y>>(&sender);
        };
        Account::deposit(sender_addr, token);
    }
}

}
}