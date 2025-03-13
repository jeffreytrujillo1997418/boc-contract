module aries_interface::oracle {

    use aptos_std::type_info::TypeInfo;

    use aries_interface::decimal::Decimal;
    use aries_interface::decimal;

    /// get the price of CoinType in USD
    /// @param coin_type - the coin type
    public fun get_price(
        _coin_type: TypeInfo
    ): Decimal {
        decimal::zero()
    }
}