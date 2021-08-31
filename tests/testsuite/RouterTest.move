//! account: firstcoin, 0x100
//! sender: firstcoin
address init_firstcoin_address = {{firstcoin}};
script {

    use 0x300::SwapScripts;
    
    // init_config
    fun init_config(sender: signer) {
        SwapScripts::init_config(sender,30u128,5u128,0u128,0u128,0u128,0u128,0u128);
    }
}

//! new-transaction
//! sender: firstcoin
address createpair_firstcoin_address = {{firstcoin}};
script {

    use 0x1::STC::STC;
    use 0x1::DummyToken::DummyToken;
    use 0x300::SwapScripts;

    // create_pair
    fun create_pair(sender: signer) {
        SwapScripts::create_pair<STC, DummyToken>(sender);
    }
}

// //! new-transaction
// //! sender: firstcoin
// address initlptoken_firstcoin_address = {{firstcoin}};
// script {

//     use 0x1::STC::STC;
//     use 0x1::DummyToken::DummyToken;
//     use 0x300::SwapScripts;

//     // init_lp_token
//     fun init_lp_token(sender: signer) {
//         SwapScripts::init_lp_token<STC, DummyToken>(sender);
//     }
// }

// //! new-transaction
// //! sender: firstcoin
// address add_firstcoin_address = {{firstcoin}};
// script {

//     use 0x1::STC::STC;
//     use 0x1::DummyToken::DummyToken;
//     use 0x200::SwapScripts;
//     const MULTIPLE: u128 = 1000000000;

//     // add_liquidity
//     fun add_liquidity(sender: signer) {
//         SwapScripts::add_liquidity<STC, DummyToken>(sender, 2000000*MULTIPLE , 1000000*MULTIPLE, 20*MULTIPLE, 10*MULTIPLE);
//     }
// }

// //! new-transaction
// //! account: firstcoin, 20000000000 0x1::STC::STC
// //! sender: firstcoin
// address swap_exact_token_for_toke_address = {{firstcoin}};
// script {
//     use 0x1::Account;
//     use 0x1::STC::STC;
//     use 0x1::DummyToken::DummyToken;
//     const MULTIPLE: u128 = 1000000000;

//     fun swap_exact_token_for_token(sender: signer) {
//         // swap
//         SwapScripts::swap_exact_token_for_token<STC, DummyToken>(&sender, 1*MULTIPLE , 100*MULTIPLE);
//     }
// }

// //! new-transaction
// //! account: firstcoin, 20000000000 0x1::STC::STC
// //! sender: firstcoin
// address swap_token_for_exact_token_address = {{firstcoin}};
// script {
//     use 0x1::Account;
//     use 0x1::STC::STC;
//     use 0x1::DummyToken::DummyToken;
//     const MULTIPLE: u128 = 1000000000;

//     fun swap_token_for_exact_token(sender: signer) {

//         // swap
//         SwapScripts::swap_token_for_exact_token<STC, DummyToken>(&sender, 1*MULTIPLE , 100*MULTIPLE);
//     }
// }