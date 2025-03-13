module boc::aries_strategy {

    use std::string::utf8;

    use aptos_std::type_info;

    use aries_interface::controller;
    use aries_interface::profile;

    friend boc::vault;

    

    use aries_interface::decimal::{Self, Decimal};

    
    public entry fun register_user(account: &signer) {
        let profile_name: vector<u8> = b"default";
        controller::register_user(account, profile_name);
    }

    
    public entry fun deposit<CoinType>(account: &signer, profile_name: vector<u8>, amount: u64) {
        controller::deposit<CoinType>(account, profile_name, amount, false);
    }

    
    public entry fun repay<CoinType>(account: &signer, profile_name: vector<u8>, amount: u64) {
        controller::deposit<CoinType>(account, profile_name, amount, false);
    }

    
    public entry fun withdraw<CoinType>(account: &signer, profile_name: vector<u8>, amount: u64) {
        controller::withdraw<CoinType>(account, profile_name, amount, false);
    }

    
    public entry fun borrow<CoinType>(account: &signer, profile_name: vector<u8>, amount: u64) {
        controller::withdraw<CoinType>(account, profile_name, amount, false);
    }
}