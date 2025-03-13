


module boc::boc_account {
    use std::signer;

    use aptos_framework::account::{Self, SignerCapability};

    
    const ERR_NOT_ENOUGH_PERMISSIONS: u64 = 1;

    
    
    struct CapabilityStorage has key { signer_cap: SignerCapability }

    
    
    
    
    public entry fun initialize_boc_account(
        boc: &signer,
        
        
    ) {
        assert!(signer::address_of(boc) == @boc, ERR_NOT_ENOUGH_PERMISSIONS);

        
        let (boc_acc, signer_cap) = account::create_resource_account(boc, b"boc");

        
        
        
        
        

        move_to(boc, CapabilityStorage { signer_cap });
    }

    
    
    public fun retrieve_signer_cap(boc: &signer): SignerCapability
    acquires CapabilityStorage {
        assert!(signer::address_of(boc) == @boc, ERR_NOT_ENOUGH_PERMISSIONS);
        let CapabilityStorage {
            signer_cap
        } = move_from<CapabilityStorage>(signer::address_of(boc));
        signer_cap
    }
}