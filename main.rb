# coding:utf-8
require 'ruby_coincheck_client'
require 'bigdecimal'
require 'uri'
require 'openssl'
require 'logger'
require './currency'
require 'date'

API_KEY = ENV['coincheck_api_key']
SECRET_KEY = ENV['coincheck_secret_key']
BASE_URL ='https://coincheck.jp/'
SSL_FLAG = true
BUY_CONDITIONS = 30
SELL_CONDITIONS = 35
LOG_WRITE_PATH = './'

log = Logger.new('out.log', 'daily')

class CoincheckClientCustom < CoincheckClient
  def read_rate(pair)
    uri = URI.parse BASE_URL + "/api/rate/#{pair}"
    request_for_get(uri)
  end

  private
  def get_signature(uri, key, secret, body = "")
    nonce = Time.now.to_i.to_s + format('%06d', Time.now.usec)
    message = nonce + uri.to_s + body
    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), secret, message)
    headers = {
        "Content-Type" => "application/json",
        "ACCESS-KEY" => key,
        "ACCESS-NONCE" => nonce,
        "ACCESS-SIGNATURE" => signature
    }
  end
end

# 既存のライブラリに無かったので追加しました




cc = CoincheckClientCustom.new(API_KEY, SECRET_KEY,
                         {base_url: BASE_URL,
                          ssl: SSL_FLAG})
#無限ループすっぞ
loop do
  begin
    #リップルの現在のレート
    response = cc.read_rate(Pair::XRP_JPY)
    xrp_rate = JSON.parse(response.body)

    #所持リップル数
    xrp_balance = JSON.parse(cc.read_balance.body)
    has_xrp = xrp_balance['xrp']
    # レート取得時刻
    now = Time.now

    # 売る時
    if has_xrp != 0

      if BigDecimal(xrp_rate['rate']) > SELL_CONDITIONS

        response = cc.create_orders(order_type: "sell",
                                    rate: SELL_CONDITIONS,
                                    amount: has_xrp,
                                    pair: Pair::XRP_JPY)
        j = JSON.parse(response.body)

        if j['success']
          log.info("【売】 リップル売りました idは#{j['id']} レートは#{j['rate']} 量は#{j['amount']}  日時は#{j['created_at']}")
          balance_json = JSON.parse(cc.read_balance.body)
          log.info("【売】 現在残高（円）は #{balance_json['jpy']}")
        else
          log.error("【エラー】　よくわからないけどたぶんエラーです #{j}")
        end

      else

        log.info("リップル売らないよ レートは#{xrp_rate['rate']} 日時は#{now.strftime('%Y/%m/%d %H:%M:%S')}")
      end

    end


    #買う時
    if BigDecimal(xrp_rate['rate']) < BUY_CONDITIONS
      response = cc.create_orders(order_type: 'market_buy_amount',
                                  rate: BUY_CONDITIONS,
                                  market_buy_amount: '10000',
                                  pair: Pair::XRP_JPY)
      j = JSON.parse(response.body)

      if j['success']

      else
        log.error("【エラー】　よくわからないけどたぶんエラーです #{j}")
      end

    else
      log.info("リップル買わないよ レートは#{xrp_rate['rate']} 日時は#{now.strftime('%Y/%m/%d %H:%M:%S')}")
    end

  rescue => e
    log.error("なんかエラーだって#{Time.now.strftime('%Y/%m/%d %H:%M:%S')}")
    log.error(e.class)
    log.error(e.message)
    log.error(e.backtrace)
    log.error('なんかエラーここまで')
  end
  sleep 10
end

