require 'logstash/devutils/rspec/spec_helper'
require 'logstash/outputs/google_pubsub'
require 'logstash/outputs/pubsub/client'
require 'logstash/codecs/plain'
require 'logstash/event'
require 'json'

describe LogStash::Outputs::GooglePubsub do
  let(:config) { {
      'project_id' => 'my-project',
      'topic' => 'my-topic',
      'delay_threshold_secs' => 1,
      'message_count_threshold' => 2,
      'request_byte_threshold' => 3,
      'attributes' => {'foo' => 'bar'}
  } }
  let(:sample_event) { LogStash::Event.new({'key'=>'value'}) }

  let(:pubsub_client) { double('pubsub-api-client') }
  let(:batching_settings) { double('batching-settings') }

  subject { LogStash::Outputs::GooglePubsub.new(config) }


  before(:each) do
    delay = config['delay_threshold_secs']
    count = config['message_count_threshold']
    bytes = config['request_byte_threshold']

    allow(LogStash::Outputs::Pubsub::Client).to receive(:build_batch_settings).and_return(batching_settings)
    expect(LogStash::Outputs::Pubsub::Client).to receive(:build_batch_settings).with(bytes, delay, count)

    allow(LogStash::Outputs::Pubsub::Client).to receive(:new).and_return(pubsub_client)
    expect(LogStash::Outputs::Pubsub::Client).to receive(:new)

    allow(pubsub_client).to receive(:build_message)
    subject.register
  end

  describe '#multi_receive_encoded' do
    it 'sends the message as JSON text by default' do
      expect(pubsub_client).to receive(:publish_message).with(/"key":"value"/, anything)

      subject.multi_receive([sample_event])
    end

    it 'sends attributes' do
      expect(pubsub_client).to receive(:publish_message).with(anything, config['attributes'])

      subject.multi_receive([sample_event])
    end
  end

  describe '#stop' do
    it 'calls shutdown on the pubsub client' do
      expect(pubsub_client).to receive(:shutdown)

      subject.stop
    end
  end

  describe '#full_topic' do
    it 'formats the topic correctly' do
      expect(subject.full_topic).to eq('projects/my-project/topics/my-topic')
    end
  end
end
