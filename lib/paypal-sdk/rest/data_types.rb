module PayPal::SDK
  module REST
    module DataTypes
      class Base < Core::API::DataTypes::Base
        attr_accessor :request_id, :headers, :error

        def initialize(hash = {})
          populate hash
        end

        def request_id
          @request_id ||= UUIDTools::UUID.random_create.to_s
        end

        def headers
          @headers ||= {}
        end

        def success?
          self.error.nil?
        end

        protected
        def populate(hash)
          hash.each { |name, value| send "#{name}=", value }
        end

        def request_headers
          self.headers.merge! 'PayPal-Request-Id' => request_id.to_s
        end

        def strip_hash(hash)
          hash.delete_if { |k, v| v == nil or v == {} or v == [] }
        end
      end

      class Payment < Base
        include RequestDataType

        attr_accessor :id, :intent, :state, :payer, :transactions, :redirect_urls, :links, :token, :create_time,
                      :update_time

        def self.find(id)
          path = "v1/payments/payment/#{id}"
          response = api.get path
          self.new response
        end

        def self.all(options = {})
          path = 'v1/payments/payment'
          response = api.get path, options
          PaymentHistory.new response
        end

        def create
          path = 'v1/payments/payment'
          response = api.post path, self.to_hash, request_headers
          populate response
          success?
        end

        def execute(payment_execution)
          payment_execution = PaymentExecution.new(payment_execution) unless payment_execution.is_a? PaymentExecution
          path = "v1/payments/payment/#{self.id}/execute"
          response = api.post path, payment_execution.to_hash, request_headers
          populate response
          success?
        end

        def link_for(rel)
          result = @links.select { |o| o.rel == rel }
          result.empty? ? nil : result[0]
        end

        def token
          @token ||= parse_token
        end

        def payer
          @payer ||= Payer.new
        end

        def payer=(value)
          @payer = value.is_a?(Payer) ? value : Payer.new(value)
        end

        def transactions
          @transactions ||= []
        end

        def transactions=(value)
          @transactions = value.collect { |o| o.is_a?(Transaction) ? o : Transaction.new(o) }
        end

        def redirect_urls
          @redirect_urls ||= RedirectUrls.new
        end

        def redirect_urls=(value)
          @redirect_urls = value.is_a?(RedirectUrls) ? value : RedirectUrls.new(value)
        end

        def links
          @links ||= []
        end

        def links=(value)
          @links = value.collect { |o| o.is_a?(Link) ? o : Link.new(o) }
        end

        def create_time
          @create_time ||= Time.now.iso8601
        end

        def update_time
          @create_time ||= Time.now.iso8601
        end

        def to_hash
          strip_hash id: self.id, intent: self.intent, state: self.state, payer: self.payer.to_hash,
                     transactions: self.transactions.collect { |o| o.to_hash },
                     redirect_urls: self.redirect_urls.to_hash, links: self.links.collect { |o| o.to_hash },
                     create_time: self.create_time, update_time: self.update_time
        end

        private
        def parse_token
          return nil if links.empty?
          approval_url = link_for('approval_url')
          return nil if approval_url.nil?
          /\S+token=([\w-]+)/.match(approval_url.href)[1]
        end
      end

      class CreditCard < Base
        include RequestDataType

        attr_accessor :id, :number, :type, :expire_month, :expire_year, :cvv2, :first_name, :last_name,
                      :billing_address, :payer_id, :state, :valid_until, :links

        def self.find(id)
          path = "v1/vault/credit-card/#{id}"
          response = api.get path
          self.new response
        end

        def create
          path = 'v1/vault/credit-card'
          response = api.post path, self.to_hash, request_headers
          populate response
          success?
        end

        def delete
          path = "v1/vault/credit-card/#{self.id}"
          response = api.delete path, {}
          populate response
          success?
        end

        def to_hash
          strip_hash id: self.id, number: self.number, type: self.type, expire_month: self.expire_month,
                     expire_year: self.expire_year, cvv2: self.cvv2, first_name: self.first_name,
                     last_name: self.last_name, billing_address: self.billing_address, payer_id: self.payer_id,
                     state: self.state, valid_until: self.valid_until, links: self.links
        end
      end

      class Sale < Base
        include RequestDataType

        attr_accessor :id, :create_time, :update_time, :amount, :state, :pending_reason, :parent_payment, :links

        def self.find(id)
          path = "v1/payments/sale/#{id}"
          response = api.get path
          self.new response
        end

        def refund(refund)
          refund = Refund.new(refund) unless refund.is_a? Refund
          path = "v1/payments/sale/#{self.id}/refund"
          response = api.post path, refund.to_hash, request_headers
          Refund.new response
        end

        def amount
          @amount ||= Amount.new
        end

        def amount=(value)
          @amount = value.is_a?(Amount) ? value : Amount.new(value)
        end

        def links
          @links ||= []
        end

        def links=(value)
          @links = value.collect { |o| o.is_a?(Link) ? o : Link.new(o) }
        end

        def to_hash
          strip_hash id: self.id, create_time: self.create_time, update_time: self.update_time,
                     amount: self.amount.to_hash, state: self.state, parent_payment: self.parent_payment,
                     link: self.links.collect { |o| o.to_hash }
        end
      end

      class Authorization < Base
        include RequestDataType

        attr_accessor :id, :create_time, :update_time, :amount, :state, :parent_payment, :valid_until, :links

        def self.find(id)
          path = "v1/payments/authorization/#{id}"
          response = api.get path
          self.new response
        end

        def capture(capture)
          capture = Capture.new(capture) unless capture.is_a? Capture
          path = "v1/payments/authorization/#{self.id}/capture"
          response = api.post path, capture.to_hash, request_headers
          Capture.new response
        end

        def void
          path = "v1/payments/authorization/#{self.id}/void"
          response = api.post path, {}, request_headers
          populate response
          success?
        end

        def reauthorize
          path = "v1/payments/authorization/#{self.id}/reauthorize"
          response = api.post path, self.to_hash, request_headers
          populate response
          success?
        end

        def to_hash
          strip_hash id: self.id, create_time: self.create_time, update_time: self.update_time, amount: self.amount,
                     state: self.state, parent_payment: self.parent_payment, valid_until: self.valid_until,
                     links: self.links
        end
      end

      class Capture < Base
        include RequestDataType

        attr_accessor :id, :create_time, :update_time, :amount, :is_final_capture, :state, :parent_payment, :links

        def self.find(id)
          path = "v1/payments/capture/#{id}"
          response = api.get path
          self.new response
        end

        def refund(refund)
          refund = Refund.new(refund) unless refund.is_a? Refund
          path = "v1/payments/capture/#{self.id}/refund"
          response = api.post path, refund.to_hash, request_headers
          Refund.new response
        end

        def final_capture?
          self.is_final_capture
        end

        def to_hash
          strip_hash id: self.id, create_time: self.create_time, update_time: self.update_time, amount: self.amount,
                     is_final_capture: self.is_final_capture, state: self.state, parent_payment: self.parent_payment,
                     links: self.links
        end
      end

      class Refund < Base
        include RequestDataType

        attr_accessor :id, :create_time, :amount, :state, :sale_id, :capture_id, :parent_payment, :links

        def self.find(id)
          path = "v1/payments/refund/#{id}"
          response = api.get path
          self.new response
        end

        def to_hash
          strip_hash id: self.id, create_time: self.create_time, amount: self.amount, state: self.state,
                     sale_id: self.sale_id, capture_id: self.capture_id, parent_payment: self.parent_payment,
                     links: self.links
        end
      end

      class Payer < Base
        attr_accessor :payment_method, :funding_instruments, :payer_info

        def payer_info
          @payer_info ||= PayerInfo.new
        end

        def payer_info=(value)
          @payer_info = value.is_a?(PayerInfo) ? value : PayerInfo.new(value)
        end

        def to_hash
          strip_hash payment_method: self.payment_method, funding_instruments: self.funding_instruments,
                     payer_info: self.payer_info.to_hash
        end
      end

      class FundingInstrument < Base
        attr_accessor :credit_card, :credit_card_token

        def to_hash
          strip_hash credit_card: self.credit_card, credit_card_token: self.credit_card_token
        end
      end

      class Address < Base
        attr_accessor :line1, :line2, :city, :country_code, :postal_code, :state, :phone

        def to_hash
          strip_hash line1: self.line1, line2: self.line2, city: self.city, country_code: self.country_code,
                     postal_code: self.postal_code, state: self.state, phone: self.phone
        end
      end

      class Link < Base
        attr_accessor :href, :rel, :target_schema, :method, :enctype, :schema

        def to_hash
          strip_hash href: self.href, rel: self.rel, target_schema: self.target_schema, method: self.method,
                     enctype: self.enctype, schema: self.schema
        end
      end

      class HyperSchema < Base
        attr_accessor :links, :fragment_resolution, :readonly, :content_encoding, :path_start, :media_type

        def to_hash
          strip_hash links: self.links, fragment_resolution: self.fragment_resolution, readonly: self.readonly,
                     content_encoding: self.content_encoding, path_start: self.path_start, media_type: self.media_type
        end
      end

      class CreditCardToken < Base
        attr_accessor :credit_card_id, :payer_id, :last4, :type, :expire_month, :expire_year

        def to_hash
          strip_hash credit_card_id: self.credit_card_id, payer_id: self.payer_id, last4: self.last4, type: self.type,
                     expire_month: self.expire_month, expire_year: self.expire_year
        end
      end

      class PayerInfo < Base
        attr_accessor :email, :first_name, :last_name, :payer_id, :phone, :shipping_address

        def shipping_address
          @shipping_address ||= Address.new
        end

        def shipping_address=(value)
          @shipping_address = value.is_a?(Address) ? value : Address.new(value)
        end

        def to_hash
          strip_hash email: self.email, first_name: self.first_name, last_name: self.last_name, payer_id: self.payer_id,
                     phone: self.phone, shipping_address: self.shipping_address.to_hash
        end
      end

      class Transaction < Base
        attr_accessor :amount, :payee, :description, :item_list, :related_resources, :transactions

        def amount
          @amount ||= Amount.new
        end

        def amount=(value)
          @amount = value.is_a?(Amount) ? value : Amount.new(value)
        end

        def related_resources
          @related_resources ||= RelatedResource.new
        end

        def related_resources=(value)
          @related_resources = value.collect { |o| o.is_a?(RelatedResource) ? o : RelatedResource.new(o) }
        end

        def to_hash
          strip_hash amount: self.amount.to_hash, payee: self.payee, description: self.description,
                     item_list: self.item_list, related_resources: self.related_resources.to_hash,
                     transactions: self.transactions
        end
      end

      class Amount < Base
        attr_accessor :total, :currency, :details

        def details
          @detail ||= AmountDetails.new
        end

        def details=(value)
          @details = value.is_a?(AmountDetails) ? value : AmountDetails.new(value)
        end

        def to_hash
          strip_hash total: self.total, currency: self.currency, details: self.details.to_hash
        end
      end

      class AmountDetails < Base
        attr_accessor :shipping, :subtotal, :tax, :free

        def to_hash
          strip_hash shipping: self.shipping, subtotal: self.subtotal, tax: self.tax, free: self.free
        end
      end

      class Payee < Base
        attr_accessor :email, :merchant_id, :phone

        def to_hash
          strip_hash email: self.email, merchant_id: self.merchant_id, phone: self.phone
        end
      end

      class Item < Base
        attr_accessor :quantity, :name, :price, :currency, :sku

        def to_hash
          strip_hash quantity: self.quantity, name: self.name, price: self.price, currency: self.currency, sku: self.sku
        end
      end

      class ShippingAddress < Base
        attr_accessor :recipient_name

        def to_hash
          strip_hash recipient_name: self.recipient_name
        end
      end

      class ItemList < Base
        attr_accessor :items, :shipping_address

        def to_hash
          strip_hash items: self.items, shipping_address: self.shipping_address
        end
      end

      class RelatedResource < Base
        attr_accessor :sale, :authorization, :capture, :refund

        def sale
          @sale ||= Sale.new
        end

        def sale=(value)
          @sale = value.is_a?(Sale) ? value : Sale.new(value)
        end

        def to_hash
          strip_hash sale: self.sale.to_hash, authorization: self.authorization, capture: self.capture,
                     refund: self.refund
        end
      end

      class RedirectUrls < Base
        attr_accessor :return_url, :cancel_url

        def to_hash
          strip_hash return_url: self.return_url, cancel_url: self.cancel_url
        end
      end

      class PaymentHistory < Base
        attr_accessor :payments, :count, :next_id

        def to_hash
          strip_hash payments: self.payments, count: self.count, next_id: self.next_id
        end
      end

      class PaymentExecution < Base
        attr_accessor :payer_id, :transactions

        def to_hash
          strip_hash payer_id: self.payer_id, transactions: self.transactions
        end
      end

      class Transactions < Base
        attr_accessor :amount

        def to_hash
          strip_hash amount: self.amount
        end
      end

      class CreditCardHistory < Base
        attr_accessor :credit_cards, :count, :next_id

        def to_hash
          strip_hash credit_cards: self.credit_cards, count: self.count, next_id: self.next_id
        end
      end

      constants.each do |data_type_klass|
        data_type_klass = const_get(data_type_klass)
        data_type_klass.load_members if defined? data_type_klass.load_members
      end
    end
  end
end
