require 'ruby_coincheck_client'
require 'bigdecimal'
require 'uri'
require 'openssl'
require './currency'

API_KEY = ENV['coincheck_api_key']
SECRET_KEY = ENV['coincheck_secret_key']
BASE_URL ='https://coincheck.jp/'
SSL_FLAG = true
BUY_CONDICTIONS = 32
SELL_CONDICTIONS = 37


class CoincheckClient
  def read_rate(pair)
    uri = URI.parse BASE_URL + "/api/rate/#{pair}"
    request_for_get(uri)
  end
end



cc = CoincheckClient.new(API_KEY, SECRET_KEY,
                                  {base_url: BASE_URL,
                                   ssl:SSL_FLAG
                                  })
#リップルの現在のレート
response = cc.read_rate(Pair::XRP_JPY)
xrp_rate = JSON.parse(response.body)

#所持リップル数
xrp_balance = JSON.parse(cc.read_balance.body)
has_xrp = xrp_balance['xrp']
has_xrp


#売る時
if has_xrp != 0

  if BigDecimal(xrp_rate['rate']) > SELL_CONDICTIONS
    cc.create_orders(order_type:"sell",
                     rate:SELL_CONDICTIONS,
                     amount:has_xrp,
                      pair:Pair::XRP_JPY)
    puts 'リップル！売るよ！'
  else
    puts 'リップル売らないよ！'
  end

end


#買う時
if BigDecimal(xrp_rate['rate']) < BUY_CONDICTIONS
  cc.create_orders(order_type:"market_buy_amount ",
                    rate:BUY_CONDICTIONS,
                   market_buy_amount:'10000',
                   pair:Pair::XRP_JPY
  )
  puts 'リップル買うよ！'
else
  puts 'リップル買わないよ！'
end

puts xrp_rate['rate']