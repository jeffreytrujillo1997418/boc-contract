module boc::oracle {
    
    

    use aptos_framework::coin;
    use aptos_framework::aptos_coin;

    use pyth::pyth;
    use pyth::price_identifier;
    use pyth::price::{Self};
    use pyth::i64::I64;

    const APTOS_USD_PRICE_FEED_IDENTIFIER : vector<u8> = x"44a93dddd8effa54ea51076c4e851b6cbbfd938e82eb90197de38fe8876bb66e";

    public fun update_and_fetch_price(receiver : &signer,  vaas : vector<vector<u8>>) : I64 {
        let coins = coin::withdraw<aptos_coin::AptosCoin>(receiver, pyth::get_update_fee(&vaas)); 
        pyth::update_price_feeds(vaas, coins); 
        let aptPrice = pyth::get_price(price_identifier::from_byte_vec(APTOS_USD_PRICE_FEED_IDENTIFIER)); 
        price::get_price(&aptPrice)
    }
}