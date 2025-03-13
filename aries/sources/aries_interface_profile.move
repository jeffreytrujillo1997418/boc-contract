module aries_interface::profile {

    use std::string::String;

    use aptos_std::type_info::TypeInfo;

    use aries_interface::decimal::{Self, Decimal};

    friend aries_interface::controller;

    struct CheckEquity {
        user_addr: address,
        profile_name: String
    }

    /// get the amount of available borrowing power for a user's account in USD
    /// @param user_address - the address to get the amount for
    /// @param account - the name of the account to get the amount for
    public fun available_borrowing_power(
        _user_address: address,
        _account: String
    ): Decimal {
        decimal::zero()
    }

    /// get the amount of coin_type borrowed for a user's account in USD
    /// @param user_address - the address to get the amount for
    /// @param account - the name of the account to get the amount for
    public fun get_borrowed_amount(
        _user_address: address,
        _account: String,
        _coin_type: TypeInfo
    ): Decimal {
        decimal::zero()
    }

    /// get the amount of coin_type supplied for a user's account in USD
    /// @param user_address - the address to get the amount for
    /// @param account - the name of the account to get the amount for
    /// @param coin_type - the type of coin to get the amount for
    public fun get_deposited_amount(
        _user_address: address,
        _account: String,
        _coin_type: TypeInfo
    ): u64 {
        0
    }

    /// withdraw a flash loan of amount for coin_type user_address's account
    /// @param user_address - the address to withdraw the loan for
    /// @param account - the name of the account to withdraw the loan for
    /// @param coin_type - the type of coin to withdraw the loan for
    /// @param amount - the amount of the loan to withdraw
    /// @param bool - UNKNOWN
    public(friend) fun withdraw_flash_loan(
        _user_address: address,
        _account: String,
        _coin_type: TypeInfo,
        _amount: u64,
        _bool: bool,
    ): (u64, u64, CheckEquity) {
        (0, 0, CheckEquity {
            user_addr: _user_address,
            profile_name: _account
        })
    }

    /// destroy a CheckEquity object and return its values
    /// @param check_equity - the CheckEquity object to destroy
    public(friend) fun read_check_equity_data(
        check_equity: CheckEquity
    ): (address, String) {
        let CheckEquity {
            user_addr,
            profile_name
        } = check_equity;
        (user_addr, profile_name)
    }

}