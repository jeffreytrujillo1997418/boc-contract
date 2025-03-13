#[test_only]
module boc::test_vault {

    use std::signer;

    use aptos_framework::coin;
    use aptos_framework::aptos_coin::{Self, AptosCoin};

    use boc::vault_coin::VaultCoin;

    use boc::vault::{Self, VaultCapability};
    use boc::setup_tests;

    const ERR_CREATE_VAULT: u64 = 1;
    const ERR_DEPOSIT_WITHDRAW: u64 = 3;

    const USER_DEPOSIT: u64 = 1000;

    fun setup_tests(aptos_framework: &signer, boc: &signer, user: &signer) {
        setup_tests::setup_tests_with_user(aptos_framework, boc, user, USER_DEPOSIT);
    }

    fun create_vault(
        boc_coins_account: &signer,
    ): VaultCapability<AptosCoin> {
        vault::new_test<AptosCoin>(boc_coins_account)
    }

    fun setup_tests_with_vault(
        aptos_framework: &signer,
        boc: &signer,
        boc_coins_account: &signer,
        user: &signer
    ): VaultCapability<AptosCoin> {
        setup_tests(aptos_framework, boc, user);
        create_vault(boc_coins_account)
    }

    fun cleanup_tests(vault_cap: VaultCapability<AptosCoin>) {
        vault::test_destroy_vault_cap(vault_cap);
    }

    #[test(aptos_framework=@aptos_framework, vault_manager=@boc, boc_coins_account=@boc, user=@0x46)]
    fun test_create_vault(
        aptos_framework: &signer,
        vault_manager: &signer,
        boc_coins_account: &signer,
        user: &signer
    ){
        setup_tests(aptos_framework, vault_manager, user);
        let vault_cap = create_vault(boc_coins_account);

        assert!(coin::decimals<VaultCoin<AptosCoin>>() == coin::decimals<AptosCoin>(), ERR_CREATE_VAULT);
        
        assert!(vault::get_debt_ratio(&vault_cap) == 0, ERR_CREATE_VAULT);
        assert!(vault::get_total_debt(&vault_cap) == 0, ERR_CREATE_VAULT);

        assert!(vault::has_coin<AptosCoin, AptosCoin>(&vault_cap), 0);
        assert!(vault::balance<AptosCoin, AptosCoin>(&vault_cap) == 0, 0);

        cleanup_tests(vault_cap);
    }

    

    #[test(aptos_framework=@aptos_framework, vault_manager=@boc, boc_coins_account=@boc, user=@0x46)]
    fun test_deposit(
        aptos_framework: &signer,
        vault_manager: &signer,
        boc_coins_account: &signer,
        user: &signer
    ){
        let vault_cap = setup_tests_with_vault(aptos_framework, vault_manager, boc_coins_account, user);

        let user_address = signer::address_of(user);

        aptos_coin::mint(aptos_framework, user_address, USER_DEPOSIT);
        vault::test_deposit<AptosCoin, AptosCoin>(&vault_cap, coin::withdraw<AptosCoin>(user, USER_DEPOSIT));
        assert!(vault::balance<AptosCoin, AptosCoin>(&vault_cap) == USER_DEPOSIT, ERR_DEPOSIT_WITHDRAW);
        cleanup_tests(vault_cap);
    }
}