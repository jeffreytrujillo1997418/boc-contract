module boc::vault {

    use std::signer;
    use std::string;
    use std::option;

    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::coin::{Self, Coin, MintCapability, BurnCapability, FreezeCapability};

    use aptos_std::type_info;

    use boc::vault_coin::VaultCoin;

    use boc::math;

    use boc::aries_strategy;

    friend boc::boc;

    

    

    struct CoinStore<phantom CoinType> has key {
        coin: Coin<CoinType>,
        deposit_events: EventHandle<DepositEvent>,
        withdraw_events: EventHandle<WithdrawEvent>,
    }

    struct Vault<phantom AptosCoin> has key {
        debt_ratio: u64,
        total_debt: u64,
        user_deposit_events: EventHandle<UserDepositEvent>,
        user_withdraw_events: EventHandle<UserWithdrawEvent>
    }

    struct VaultCoinCaps<phantom AptosCoin> has key {
        mint_cap: MintCapability<VaultCoin<AptosCoin>>,
        freeze_cap: FreezeCapability<VaultCoin<AptosCoin>>,
        burn_cap: BurnCapability<VaultCoin<AptosCoin>>,
    }

    

    struct VaultCapability<phantom AptosCoin> has store {
        signer_cap: SignerCapability,
    }

    struct UserCapability<phantom AptosCoin> {
        vault_cap: VaultCapability<AptosCoin>,
        user_addr: address,
    }

    

    
    struct DepositEvent has drop, store {
        amount: u64,
    }

    struct WithdrawEvent has drop, store {
        amount: u64,
    }

    
    
    
    
    
    struct UserDepositEvent has drop, store {
        user_addr: address,
        base_coin_amount: u64,
        vault_coin_amount: u64,
    }

    struct UserWithdrawEvent has drop, store {
        user_addr: address,
        base_coin_amount: u64,
        vault_coin_amount: u64,
    }

    
    
    
    public(friend) fun get_user_capability<AptosCoin>(
        user: &signer,
        vault_cap: VaultCapability<AptosCoin>
    ): UserCapability<AptosCoin> {
        UserCapability {
            vault_cap,
            user_addr: signer::address_of(user),
        }
    }

    
    
    public(friend) fun destroy_user_capability<AptosCoin>(
        user_cap: UserCapability<AptosCoin>
    ): (VaultCapability<AptosCoin>, address) {
        let UserCapability {
            vault_cap,
            user_addr,
        } = user_cap;
        (vault_cap, user_addr)
    }

    

    public fun new<AptosCoin>(boc_coins_account: &signer): VaultCapability<AptosCoin> {
        
        let vault_coin_name = string::utf8(type_info::struct_name(&type_info::type_of<AptosCoin>()));
        string::append_utf8(&mut vault_coin_name, b" Vault");
        let seed = copy vault_coin_name;

        
        let (vault_acc, signer_cap) = account::create_resource_account(
            boc_coins_account,
            *string::bytes(&seed),
        );

        let base_coin_decimals = coin::decimals<AptosCoin>();
        let vault = Vault<AptosCoin> {
            debt_ratio: 0,
            total_debt: 0,
            user_deposit_events: account::new_event_handle<UserDepositEvent>(&vault_acc),
            user_withdraw_events: account::new_event_handle<UserWithdrawEvent>(&vault_acc),
        };
        move_to(&vault_acc, vault);

        
        let vault_coin_symbol = string::utf8(b"b");
        string::append(&mut vault_coin_symbol, coin::symbol<AptosCoin>());

        
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<VaultCoin<AptosCoin>>(
            boc_coins_account,
            vault_coin_name,
            vault_coin_symbol,
            base_coin_decimals,
            true
        );
        move_to(&vault_acc, VaultCoinCaps<AptosCoin> { mint_cap, freeze_cap, burn_cap });

        
        let vault_cap = VaultCapability {
            signer_cap
        };
        add_coin<AptosCoin, AptosCoin>(&vault_cap);

        
        vault_cap
    }

    
    public(friend) fun deposit_as_user<AptosCoin>(
        user: &signer,
        user_cap: &UserCapability<AptosCoin>,
        base_coins: Coin<AptosCoin>,
    ): Coin<VaultCoin<AptosCoin>>
    acquires Vault, CoinStore, VaultCoinCaps {
        let vault_cap = &user_cap.vault_cap;
        

        let base_coin_amount = coin::value(&base_coins);
        let vault_coin_amount = calculate_vault_coin_amount_from_base_coin_amount<AptosCoin>(
            vault_cap,
            coin::value(&base_coins)
        );

        
        let vault_address = get_vault_address(vault_cap);
        let vault = borrow_global_mut<Vault<AptosCoin>>(vault_address);
        event::emit_event(&mut vault.user_deposit_events, UserDepositEvent {
            user_addr: user_cap.user_addr,
            base_coin_amount,
            vault_coin_amount
        });

        
        deposit(vault_cap, base_coins);
        let caps = borrow_global<VaultCoinCaps<AptosCoin>>(vault_address);

        
        
        aries_strategy::deposit<AptosCoin>(user, b"default", base_coin_amount);
        coin::mint<VaultCoin<AptosCoin>>(vault_coin_amount, &caps.mint_cap)
    }

    public(friend) fun withdraw_as_user<AptosCoin>(
        user: &signer,
        user_cap: &UserCapability<AptosCoin>,
        vault_coins: Coin<VaultCoin<AptosCoin>>
    ): Coin<AptosCoin>
    acquires CoinStore, Vault, VaultCoinCaps {
        let vault_cap = &user_cap.vault_cap;

        let vault_coin_amount = coin::value(&vault_coins);
        let base_coin_amount = calculate_base_coin_amount_from_vault_coin_amount<AptosCoin>(
            vault_cap,
            coin::value(&vault_coins)
        );

        let vault_address = get_vault_address(vault_cap);
        let vault = borrow_global_mut<Vault<AptosCoin>>(vault_address);
        event::emit_event(&mut vault.user_withdraw_events, UserWithdrawEvent {
            user_addr: user_cap.user_addr,
            base_coin_amount,
            vault_coin_amount,
        });

        let caps = borrow_global<VaultCoinCaps<AptosCoin>>(vault_address);
        coin::burn(vault_coins, &caps.burn_cap);
        
        
        aries_strategy::withdraw<AptosCoin>(user, b"default", base_coin_amount);
        withdraw(vault_cap, base_coin_amount)
    }


    
    public fun get_vault_address<AptosCoin>(vault_cap: &VaultCapability<AptosCoin>): address {
        account::get_signer_capability_address(&vault_cap.signer_cap)
    }

    public fun balance<AptosCoin, CoinType>(vault_cap: &VaultCapability<AptosCoin>): u64
    acquires CoinStore {
        let vault_address = get_vault_address(vault_cap);
        let store = borrow_global_mut<CoinStore<CoinType>>(vault_address);
        coin::value(&store.coin)
    }

    public fun total_assets<AptosCoin>(vault_cap: &VaultCapability<AptosCoin>): u64
    acquires Vault, CoinStore {
        let vault_address = get_vault_address(vault_cap);
        let vault = borrow_global<Vault<AptosCoin>>(vault_address);

        let balance = balance<AptosCoin, AptosCoin>(vault_cap);
        vault.total_debt + balance
    }


    public fun calculate_vault_coin_amount_from_base_coin_amount<AptosCoin>(
        vault_cap: &VaultCapability<AptosCoin>,
        base_coin_amount: u64
    ): u64
    acquires Vault, CoinStore {
        let total_base_coin_amount = total_assets<AptosCoin>(vault_cap);
        let total_supply = option::get_with_default<u128>(&coin::supply<VaultCoin<AptosCoin>>(), 0);

        if (total_supply != 0) {
            math::mul_u128_u64_div_u64_result_u64(
                total_supply,
                base_coin_amount,
                total_base_coin_amount
            )
        } else {
            base_coin_amount
        }
    }

    public fun calculate_base_coin_amount_from_vault_coin_amount<AptosCoin>(
        vault_cap: &VaultCapability<AptosCoin>,
        vault_coin_amount: u64
    ): u64 acquires Vault, CoinStore {
        let total_assets = total_assets<AptosCoin>(vault_cap);
        let share_total_supply_option = coin::supply<VaultCoin<AptosCoin>>();
        let share_total_supply = option::get_with_default<u128>(&share_total_supply_option, 0);
        math::calculate_proportion_of_u64_with_u128_denominator(
            total_assets,
            vault_coin_amount,
            share_total_supply
        )
    }

    public fun get_debt_ratio<AptosCoin>(vault_cap: &VaultCapability<AptosCoin>): u64
    acquires Vault {
        let vault_address = get_vault_address(vault_cap);
        let vault = borrow_global<Vault<AptosCoin>>(vault_address);
        vault.debt_ratio
    }

    public fun get_total_debt<AptosCoin>(vault_cap: &VaultCapability<AptosCoin>): u64
    acquires Vault {
        let vault_address = get_vault_address(vault_cap);
        let vault = borrow_global<Vault<AptosCoin>>(vault_address);
        vault.total_debt
    }

    public fun has_coin<AptosCoin, CoinType>(vault_cap: &VaultCapability<AptosCoin>): bool {
        let vault_address = get_vault_address(vault_cap);
        exists<CoinStore<CoinType>>(vault_address)
    }


    

    

    
    
    fun add_coin<AptosCoin, CoinType>(vault_cap: &VaultCapability<AptosCoin>) {
        let vault_acc = account::create_signer_with_capability(&vault_cap.signer_cap);
        move_to(&vault_acc, CoinStore<CoinType> {
            coin: coin::zero(),
            deposit_events: account::new_event_handle<DepositEvent>(&vault_acc),
            withdraw_events: account::new_event_handle<WithdrawEvent>(&vault_acc),
        })
    }

    fun deposit<AptosCoin, CoinType>(vault_cap: &VaultCapability<AptosCoin>, coin: Coin<CoinType>)
    acquires CoinStore {
        let vault_address = get_vault_address(vault_cap);
        let store = borrow_global_mut<CoinStore<CoinType>>(vault_address);
        event::emit_event(&mut store.deposit_events, DepositEvent {
            amount: coin::value(&coin)
        });
        coin::merge(&mut store.coin, coin);
    }

    fun withdraw<AptosCoin, CoinType>(vault_cap: &VaultCapability<AptosCoin>, amount: u64): Coin<CoinType>
    acquires CoinStore {
        let vault_address = get_vault_address(vault_cap);
        let store = borrow_global_mut<CoinStore<CoinType>>(vault_address);
        event::emit_event(&mut store.deposit_events, DepositEvent {
            amount
        });
        coin::extract(&mut store.coin, amount)
    }

    
    
    #[test_only]
    public fun new_test<AptosCoin>(
        governance: &signer,
    ): VaultCapability<AptosCoin> {
        new<AptosCoin>(
            governance
        )
    }

    #[test_only]
    public fun test_deposit<AptosCoin, CoinType>(
        vault_cap: &VaultCapability<AptosCoin>,
        coins: Coin<CoinType>
    ) acquires CoinStore {
        deposit(vault_cap, coins);
    }

    #[test_only]
    public fun test_destroy_vault_cap<AptosCoin>(vault_cap: VaultCapability<AptosCoin>) {
        let VaultCapability {
            signer_cap: _,
        } = vault_cap;
    }
}