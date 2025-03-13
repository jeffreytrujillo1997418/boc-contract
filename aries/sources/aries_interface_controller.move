module aries_interface::controller {

    use std::signer;
    use std::string::String;

    use aptos_framework::coin::{Self, Coin};

    use aries_interface::profile::CheckEquity;
    use aries_interface::profile;
    use aptos_std::type_info;

    public entry fun register_user(
        _user: &signer,
        _account: vector<u8>
    ) {}

    public entry fun deposit<CoinType>(
        _user: &signer,
        _account: vector<u8>,
        _amount: u64,
        _isDebtPayment: bool
    ) {}

    public entry fun withdraw<CoinType>(
        _user: &signer,
        _account: vector<u8>,
        _amount: u64,
        _isBorrow: bool
    ) {}

    public fun begin_flash_loan<CoinType>(
        user: &signer,
        account: String,
        amount: u64,
    ): (CheckEquity, Coin<CoinType>) {
        let (_, _, check_equity) = profile::withdraw_flash_loan(
            signer::address_of(user),
            account,
            type_info::type_of<CoinType>(),
            amount,
            false
        );
        (check_equity, coin::zero<CoinType>())
    }

    public fun end_flash_loan<CoinType>(
        check_equity: CheckEquity,
        coin: Coin<CoinType>,
    ) {
        let (_user_addr, _account) = profile::read_check_equity_data(check_equity);
        coin::destroy_zero(coin);
    }
}