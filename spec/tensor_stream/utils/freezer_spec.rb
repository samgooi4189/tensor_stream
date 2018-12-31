require "spec_helper"

require 'tensor_stream/utils/freezer'

RSpec.describe TensorStream::Freezer do
  let(:ts) { TensorStream }
  let(:freezer) { TensorStream::Freezer.new }
  let(:sess) { ts.session }

  specify "convert a checkpoint to a freezed model" do
    checkpoint_file = File.join('spec', 'fixtures', 'lg_model')
    y1 = freezer.convert(checkpoint_file, '/tmp/lg_model_freezed.yaml')
    actual = File.read(File.join('/tmp', 'lg_model_freezed.yaml'))
    expected = File.read(File.join('spec', 'fixtures', 'lg_model_freezed.yaml'))
    expect(actual).to eq(expected)
  end
end