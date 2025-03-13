

module boc::boc {
    use std::option::{Self, Option};
    use std::signer;

    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::account::{Self, SignerCapability};

    use boc::access_control;

    use boc::vault_coin::{VaultCoin};
    use boc::vault::{Self, VaultCapability, UserCapability};
    use boc::boc_account;

    const ERR_NOT_ENOUGH_PERMISSIONS: u64 = 1;

    

    
    
    struct BocAccount has key {
        signer_cap: SignerCapability
    }

    
    
    struct VaultInfo<phantom AptosCoin> has key {
        vault_cap: Option<VaultCapability<AptosCoin>>,
    }

    

    
    
    public entry fun initialize(boc_manager: &signer) {
        assert!(signer::address_of(boc_manager) == @boc, ERR_NOT_ENOUGH_PERMISSIONS);
        access_control::initialize(boc_manager);
        let signer_cap = boc_account::retrieve_signer_cap(boc_manager);
        move_to(boc_manager, BocAccount {
            signer_cap
        });
    }

    
    
    public entry fun new_vault<AptosCoin>(boc_manager: &signer)  {
        access_control::assert_boc_manager(boc_manager);
        let vault_cap = vault::new<AptosCoin>(boc_manager);
        move_to(boc_manager, VaultInfo<AptosCoin> {
            vault_cap: option::some(vault_cap)
        });
    }

    

    
    
    
    public entry fun deposit<AptosCoin>(user: &signer, amount: u64) acquires BocAccount, VaultInfo {
        let base_coins = coin::withdraw<AptosCoin>(user, amount);
        let user_cap = user_lock_vault<AptosCoin>(user);
        let vault_coins = vault::deposit_as_user(user, &user_cap, base_coins);
        user_unlock_vault<AptosCoin>(user_cap);
        let user_addr = signer::address_of(user);
        if(!coin::is_account_registered<VaultCoin<AptosCoin>>(user_addr)){
            coin::register<VaultCoin<AptosCoin>>(user);
        };
        coin::deposit(user_addr, vault_coins);
    }

    
    
    
    public entry fun withdraw<AptosCoin>(user: &signer, amount: u64) acquires BocAccount, VaultInfo {
        let vault_coins = coin::withdraw<VaultCoin<AptosCoin>>(user, amount);
        let user_cap = user_lock_vault<AptosCoin>(user);
        let base_coins = vault::withdraw_as_user<AptosCoin>(user, &user_cap, vault_coins);
        user_unlock_vault<AptosCoin>(user_cap);
        
        
        
        
        coin::deposit(signer::address_of(user), base_coins);
    }

    
    fun lock_vault<AptosCoin>(): VaultCapability<AptosCoin> acquires BocAccount, VaultInfo {
        let boc_account_addr = get_boc_account_addr();
        let vault_info = borrow_global_mut<VaultInfo<AptosCoin>>(@boc);
        option::extract(&mut vault_info.vault_cap)
    }

    
    
    fun unlock_vault<AptosCoin>(vault_cap: VaultCapability<AptosCoin>) acquires BocAccount, VaultInfo {
        let boc_account_addr = get_boc_account_addr();
        let vault_info = borrow_global_mut<VaultInfo<AptosCoin>>(@boc);
        option::fill(&mut vault_info.vault_cap, vault_cap);
    }

    
    
    public(friend) fun user_lock_vault<AptosCoin>(user: &signer) : UserCapability<AptosCoin> acquires BocAccount, VaultInfo {
        let vault_cap = lock_vault<AptosCoin>();
        vault::get_user_capability(user, vault_cap)
    }

    
    
    public(friend) fun user_unlock_vault<AptosCoin>(user_cap: UserCapability<AptosCoin>) acquires BocAccount, VaultInfo {
        let (vault_cap, _) = vault::destroy_user_capability(user_cap);
        unlock_vault<AptosCoin>(vault_cap);
    }

    
    
    
    
    
    
    
    
    

    
    
    
    
    
    
    
    
    
    
    
    
    

    #[view]
    
    public fun get_boc_account_addr(): address acquires BocAccount {
        let boc_account = borrow_global<BocAccount>(@boc);
        account::get_signer_capability_address(&boc_account.signer_cap)
    }

    #[view]
    
    public fun get_total_assets<AptosCoin>(): u64 acquires BocAccount, VaultInfo {
        let boc_account_addr = get_boc_account_addr();
        vault::total_assets(
            option::borrow(&borrow_global<VaultInfo<AptosCoin>>(@boc).vault_cap)
        )
    }

    #[view]
    
    public fun get_vault_address<AptosCoin>(): address acquires BocAccount, VaultInfo {
        let boc_account_address = get_boc_account_addr();
        vault::get_vault_address(
            option::borrow(&borrow_global<VaultInfo<AptosCoin>>(@boc).vault_cap)
        )
    }
}