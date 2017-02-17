module WebEngine
  class SiClient
    require 'bunny'

    def self.initialize_connection
      $rabbitmq_connection = Bunny.new(tls: true,
                                       vhost: Rails.env,
                                       tls_cert: Rails.root.join(ENV['cert_path']),
                                       tls_key: Rails.root.join(ENV['cert_key_path']),
                                       verify_peer: false,
                                       tls_ca_certificates: [(ENV['cacert_path'])])

      $rabbitmq_connection.start

      $rabbitmq_channel = $rabbitmq_connection.create_channel
    end

    def initialize
      @channel_with_topic = $rabbitmq_channel.topic(channel_name, durable: true)
      @reply_queue        = $rabbitmq_channel.queue('', exclusive: true)

      @results = Hash.new { |h, k| h[k] = Queue.new }
      reply_queue.subscribe(block: false) do |_delivery_info, properties, payload|
        results[properties[:correlation_id]].push(payload)
      end
    end

    attr_reader :reply_queue, :channel_with_topic, :results

    private

    def call(topic, status_messages, data, parse = true)
      correlation_id = SecureRandom.uuid

      reply_queue.bind(channel_with_topic, routing_key: reply_queue.name)

      channel_with_topic.publish(data.to_json,
                                 routing_key: "#{channel_name}.#{topic}",
                                 correlation_id: correlation_id,
                                 reply_to: reply_queue.name,
                                 headers: {
                                   client: 'test_client' }
                                )

      message = results[correlation_id].pop

      results.delete correlation_id
      SiResponse.new(status_messages, parse ? JSON.parse(message) : message)
    end

    def check_environment
      fail unless Rails.env.development?
    end
  end
end