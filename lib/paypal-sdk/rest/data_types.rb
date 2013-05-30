require 'paypal-sdk-core'
require 'uuidtools'

module PayPal::SDK
  module REST
    module DataTypes
      class Base < Core::API::DataTypes::Base
        attr_accessor :error
        attr_writer   :header, :request_id

        def header
          @header ||= {}
        end

        def request_id
          @request_id ||= UUIDTools::UUID.random_create.to_s
        end

        def http_header
          { "PayPal-Request-Id" => request_id.to_s }.merge(header)
        end

        def success?
          @error.nil?
        end

        def merge!(values)
          @error = nil
          super
        end

        def self.load_members
        end
      end

      class Payment < Base

        def self.load_members
          object_of :id, String
          object_of :create_time, DateTime
          object_of :update_time, DateTime
          object_of :intent, String
          object_of :payer, Payer
          array_of  :transactions, Transaction
          object_of :state, String
          object_of :redirect_urls, RedirectUrls
          array_of  :links, Links
        end

        include RequestDataType

        def create()
          path = "v1/payments/payment"
          response = api.post(path, self.to_hash, http_header)
          self.merge!(response)
          success?
        end

        class << self
          def find(resource_id)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/payments/payment/#{resource_id}"
            self.new(api.get(path))
          end
        end

        def execute(payment_execution)
          payment_execution = PaymentExecution.new(payment_execution) unless payment_execution.is_a? PaymentExecution
          path = "v1/payments/payment/#{self.id}/execute"
          response = api.post(path, payment_execution.to_hash, http_header)
          self.merge!(response)
          success?
        end

        class << self
          def all(options = {})
            path = "v1/payments/payment"
            PaymentHistory.new(api.get(path, options))
          end
        end

      end
      class Payer < Base

        def self.load_members
          object_of :payment_method, String
          array_of  :funding_instruments, FundingInstrument
          object_of :payer_info, PayerInfo
        end

      end
      class FundingInstrument < Base

        def self.load_members
          object_of :credit_card, CreditCard
          object_of :credit_card_token, CreditCardToken
        end

      end
      class CreditCard < Base

        def self.load_members
          object_of :id, String
          object_of :number, String
          object_of :type, String
          object_of :expire_month, Integer
          object_of :expire_year, Integer
          object_of :cvv2, String
          object_of :first_name, String
          object_of :last_name, String
          object_of :billing_address, Address
          object_of :payer_id, String
          object_of :state, String
          object_of :valid_until, String
          array_of  :links, Links
        end

        include RequestDataType

        def create()
          path = "v1/vault/credit-card"
          response = api.post(path, self.to_hash, http_header)
          self.merge!(response)
          success?
        end

        class << self
          def find(resource_id)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/vault/credit-card/#{resource_id}"
            self.new(api.get(path))
          end
        end

        def delete()
          path = "v1/vault/credit-card/#{self.id}"
          response = api.delete(path, {})
          self.merge!(response)
          success?
        end

      end
      class Address < Base

        def self.load_members
          object_of :line1, String
          object_of :line2, String
          object_of :city, String
          object_of :country_code, String
          object_of :postal_code, String
          object_of :state, String
          object_of :phone, String
        end

      end
      class Links < Base

        def self.load_members
          object_of :href, String
          object_of :rel, String
          object_of :targetSchema, HyperSchema
          object_of :method, String
          object_of :enctype, String
          object_of :schema, HyperSchema
        end

      end
      class HyperSchema < Base

        def self.load_members
          array_of  :links, Links
          object_of :fragmentResolution, String
          object_of :readonly, Boolean
          object_of :contentEncoding, String
          object_of :pathStart, String
          object_of :mediaType, String
        end

      end
      class CreditCardToken < Base

        def self.load_members
          object_of :credit_card_id, String
          object_of :payer_id, String
          object_of :last4, String
          object_of :type, String
          object_of :expire_month, Integer
          object_of :expire_year, Integer
        end

      end
      class PayerInfo < Base

        def self.load_members
          object_of :email, String
          object_of :first_name, String
          object_of :last_name, String
          object_of :payer_id, String
          object_of :phone, String
          object_of :shipping_address, Address
        end

      end
      class Transaction < Base

        def self.load_members
          object_of :amount, Amount
          object_of :payee, Payee
          object_of :description, String
          object_of :item_list, ItemList
          array_of  :related_resources, RelatedResources
          array_of  :transactions, Transaction
        end

      end
      class Amount < Base

        def self.load_members
          object_of :currency, String
          object_of :total, String
          object_of :details, Details
        end

      end
      class Details < Base

        def self.load_members
          object_of :shipping, String
          object_of :subtotal, String
          object_of :tax, String
          object_of :fee, String
        end

      end
      class Payee < Base

        def self.load_members
          object_of :email, String
          object_of :merchant_id, String
          object_of :phone, String
        end

      end
      class Item < Base

        def self.load_members
          object_of :quantity, String
          object_of :name, String
          object_of :price, String
          object_of :currency, String
          object_of :sku, String
        end

      end
      class ShippingAddress < Address

        def self.load_members
          object_of :recipient_name, String
        end

      end
      class ItemList < Base

        def self.load_members
          array_of  :items, Item
          object_of :shipping_address, ShippingAddress
        end

      end
      class RelatedResources < Base

        def self.load_members
          object_of :sale, Sale
          object_of :authorization, Authorization
          object_of :capture, Capture
          object_of :refund, Refund
        end

      end
      class Sale < Base

        def self.load_members
          object_of :id, String
          object_of :create_time, DateTime
          object_of :update_time, DateTime
          object_of :amount, Amount
          object_of :state, String
          object_of :parent_payment, String
          array_of  :links, Links
        end

        include RequestDataType

        class << self
          def find(resource_id)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/payments/sale/#{resource_id}"
            self.new(api.get(path))
          end
        end

        def refund(refund)
          refund = Refund.new(refund) unless refund.is_a? Refund
          path = "v1/payments/sale/#{self.id}/refund"
          response = api.post(path, refund.to_hash, http_header)
          Refund.new(response)
        end

      end
      class Authorization < Base

        def self.load_members
          object_of :id, String
          object_of :create_time, DateTime
          object_of :update_time, DateTime
          object_of :amount, Amount
          object_of :state, String
          object_of :parent_payment, String
          object_of :valid_until, String
          array_of  :links, Links
        end

        include RequestDataType

        class << self
          def find(resource_id)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/payments/authorization/#{resource_id}"
            self.new(api.get(path))
          end
        end

        def capture(capture)
          capture = Capture.new(capture) unless capture.is_a? Capture
          path = "v1/payments/authorization/#{self.id}/capture"
          response = api.post(path, capture.to_hash, http_header)
          Capture.new(response)
        end

        def void()
          path = "v1/payments/authorization/#{self.id}/void"
          response = api.post(path, {}, http_header)
          self.merge!(response)
          success?
        end

        def reauthorize()
          path = "v1/payments/authorization/#{self.id}/reauthorize"
          response = api.post(path, self.to_hash, http_header)
          self.merge!(response)
          success?
        end

      end
      class Capture < Base

        def self.load_members
          object_of :id, String
          object_of :create_time, DateTime
          object_of :update_time, DateTime
          object_of :amount, Amount
          object_of :is_final_capture, Boolean
          object_of :state, String
          object_of :parent_payment, String
          array_of  :links, Links
        end

        include RequestDataType

        class << self
          def find(resource_id)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/payments/capture/#{resource_id}"
            self.new(api.get(path))
          end
        end

        def refund(refund)
          refund = Refund.new(refund) unless refund.is_a? Refund
          path = "v1/payments/capture/#{self.id}/refund"
          response = api.post(path, refund.to_hash, http_header)
          Refund.new(response)
        end

      end
      class Refund < Base

        def self.load_members
          object_of :id, String
          object_of :create_time, DateTime
          object_of :amount, Amount
          object_of :state, String
          object_of :sale_id, String
          object_of :capture_id, String
          object_of :parent_payment, String
          array_of  :links, Links
        end

        include RequestDataType

        class << self
          def find(resource_id)
            raise ArgumentError.new("id required") if resource_id.to_s.strip.empty?
            path = "v1/payments/refund/#{resource_id}"
            self.new(api.get(path))
          end
        end

      end
      class RedirectUrls < Base

        def self.load_members
          object_of :return_url, String
          object_of :cancel_url, String
        end

      end
      class PaymentHistory < Base

        def self.load_members
          array_of  :payments, Payment
          object_of :count, Integer
          object_of :next_id, String
        end

      end
      class PaymentExecution < Base

        def self.load_members
          object_of :payer_id, String
          array_of  :transactions, Transactions
        end

      end
      class Transactions < Base

        def self.load_members
          object_of :amount, Amount
        end

      end
      class CreditCardHistory < Base

        def self.load_members
          array_of  :"credit-cards", CreditCard
          object_of :count, Integer
          object_of :next_id, String
        end

      end

      constants.each do |data_type_klass|
        data_type_klass = const_get(data_type_klass)
        data_type_klass.load_members if defined? data_type_klass.load_members
      end

    end
  end
end
