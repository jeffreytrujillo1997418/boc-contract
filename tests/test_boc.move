#[test_only]
module boc::test_boc {

    use std::signer;
    use std::debug::print;
    
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::{AptosCoin};
    use aptos_framework::timestamp;

    use boc::vault_coin::VaultCoin;

    use boc::boc;
    use boc::vault;
    use boc::setup_tests;
    use boc::test_coin;
    use boc::test_coin::USDC;

    const MANAGEMENT_FEE: u64 = 200;
    const PERFORMANCE_FEE: u64 = 2000;
    const DEBT_RATIO: u64 = 1000;
    const DEPOSIT_AMOUNT: u64 = 1000;

    const ERR_INITIALIZED: u64 = 1;
    const ERR_NEW_VAULT: u64 = 2;
    const ERR_UPDATE_FEES: u64 = 3;
    const ERR_DEPOSIT: u64 = 4;
    const ERR_WITHDRAW: u64 = 5;
    const ERR_APPROVE_STRATEGY: u64 = 6;
    const ERR_LOCK_UNLOCK: u64 = 7;
    const ERR_FREEZE: u64 = 8;

    struct TestStrategy has drop {}
    struct TestStrategy2 has drop {}

    struct TestCoin {}

    fun setup_tests(aptos_framework: &signer, boc: &signer, user: &signer) {
        setup_tests::setup_tests_with_user(aptos_framework, boc, user, DEPOSIT_AMOUNT);
    }

    fun create_vault(boc: &signer) {
        boc::new_vault<AptosCoin>(boc);
        
        
    }

    fun setup_tests_and_create_vault(aptos_framework: &signer, boc: &signer, user: &signer) {
        setup_tests(aptos_framework, boc, user);
        create_vault(boc);
    }

    fun user_deposit(user: &signer) {
        boc::deposit<AptosCoin>(user, DEPOSIT_AMOUNT);
    }

    #[test(
        aptos_framework = @aptos_framework,
        boc = @boc,
        user = @0x47
    )]
    fun test_initialize(aptos_framework: &signer, boc: &signer, user: &signer) {
        setup_tests(aptos_framework, boc, user);
    }

    
    
    
    
    
    
    
    
    
    
    
    
    

    #[test(
        aptos_framework = @aptos_framework,
        boc = @boc,
        user = @0x47
    )]
    fun test_new_vault(aptos_framework: &signer, boc: &signer, user: &signer) {
        setup_tests(aptos_framework, boc, user);
        create_vault(boc);
        assert!(boc::get_total_assets<AptosCoin>() == 0, ERR_NEW_VAULT);
        let vault_address = boc::get_vault_address<AptosCoin>();
        print(&vault_address);
    }

    
    
    
    
    
    
    
    
    
    

    
    
    
    
    
    
    
    
    
    
    

    #[test(
        aptos_framework = @aptos_framework,
        boc = @boc,
        user = @0x47
    )]
    fun test_deposit(aptos_framework: &signer, boc: &signer, user: &signer) {
        setup_tests_and_create_vault(aptos_framework, boc, user);
        user_deposit(user);
        assert!(coin::balance<VaultCoin<AptosCoin>>(signer::address_of(user)) == DEPOSIT_AMOUNT, ERR_DEPOSIT);
    }

    #[test(
        aptos_framework = @aptos_framework,
        boc = @boc,
        user = @0x47
    )]
    fun test_withdraw(aptos_framework: &signer, boc: &signer, user: &signer) {
        setup_tests_and_create_vault(aptos_framework, boc, user);
        user_deposit(user);
        boc::withdraw<AptosCoin>(user, DEPOSIT_AMOUNT);

        let user_address = signer::address_of(user);
        assert!(coin::balance<VaultCoin<AptosCoin>>(user_address) == 0, ERR_WITHDRAW);
        assert!(coin::balance<AptosCoin>(user_address) == DEPOSIT_AMOUNT, ERR_WITHDRAW);
    }
}