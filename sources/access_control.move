
module boc::access_control {
    use std::signer;

    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::event::{Self, EventHandle};

    friend boc::boc;

    
    const ERR_CONFIG_DOES_NOT_EXIST: u64 = 400;

    
    const ERR_NOT_BOC: u64 = 401;

    
    const ERR_NOT_BOC_MANAGER: u64 = 403;

    
    
    struct GlobalConfigResourceAccount has key {
        signer_cap: SignerCapability
    }

    
    
    
    
    struct GlobalConfig has key {
        boc_manager_address: address,
        new_boc_manager_address: address,
        boc_manager_change_events: EventHandle<BocManagerChangeEvent>,
    }

    
    
    struct BocManagerChangeEvent has drop, store {
        new_boc_manager_address: address,
    }

    
    
    public(friend) fun initialize(boc_manager: &signer) acquires GlobalConfig {
        assert!(signer::address_of(boc_manager) == @boc, ERR_NOT_BOC);

        let (global_config_signer, signer_cap) = account::create_resource_account(boc_manager, b"global config resource account");

        move_to(boc_manager, GlobalConfigResourceAccount {signer_cap});

        move_to(&global_config_signer, GlobalConfig {
            boc_manager_address: @boc,
            new_boc_manager_address: @0x0,
            boc_manager_change_events: account::new_event_handle<BocManagerChangeEvent>(&global_config_signer),
        });

        let global_config_account_address = signer::address_of(&global_config_signer);
        let global_config = borrow_global_mut<GlobalConfig>(global_config_account_address);
        event::emit_event(&mut global_config.boc_manager_change_events, BocManagerChangeEvent {
            new_boc_manager_address: @boc
        });
    }

    
    
    public fun assert_boc_manager(boc_manager: &signer) acquires GlobalConfig, GlobalConfigResourceAccount {
        assert!(get_boc_manager_address() == signer::address_of(boc_manager), ERR_NOT_BOC_MANAGER);
    }

    #[view]
    
    public fun get_global_config_account_address(): address acquires GlobalConfigResourceAccount {
        
        let global_config_account = borrow_global<GlobalConfigResourceAccount>(@boc);
        let global_config_account_address = account::get_signer_capability_address(&global_config_account.signer_cap);
        assert!(exists<GlobalConfig>(global_config_account_address), ERR_CONFIG_DOES_NOT_EXIST);
        global_config_account_address
    }

    #[view]
    
    public fun get_boc_manager_address(): address acquires GlobalConfig, GlobalConfigResourceAccount {
        let global_config_account_address = get_global_config_account_address();
        let config = borrow_global<GlobalConfig>(global_config_account_address);
        config.boc_manager_address
    }
}