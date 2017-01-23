=begin
    Copyright 2015 Wavefront Inc.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
   limitations under the License.

=end

require_relative '../spec_helper'
require 'pathname'
require 'json'

RESPONSE = 'test'

describe Wavefront::Response::Raw do
  it 'exposes the response' do
    response = Wavefront::Response::Raw.new(RESPONSE)
    expect(response).to respond_to(:response)
    expect(response.response).to eq RESPONSE
  end

  it 'overloads to_s and returns the response' do
    response = Wavefront::Response::Raw.new(RESPONSE)
    expect(response).to respond_to(:to_s)
    expect(response.to_s).to eq RESPONSE
  end
end

describe Wavefront::Response::Ruby do
  it 'exposes the response' do
    example_response = File.read(Pathname.new(__FILE__).parent.parent.join('example_response.json'))
    response = Wavefront::Response::Ruby.new(example_response)
    expect(response).to respond_to(:response)
    expect(response.response).to eq example_response
  end

  it 'dynamically sets accessors for each part of the response' do
    example_response = File.read(Pathname.new(__FILE__).parent.parent.join('example_response.json'))
    response = Wavefront::Response::Ruby.new(example_response)

    %w(response query name timeseries stats).each do |part|
      expect(response).to respond_to(part)
    end
  end
end

describe Wavefront::Response::Graphite do
  include Wavefront::Mixins
  include JSON
  it 'returns something that resembles some graphite output' do
    example_response = File.read(Pathname.new(__FILE__).parent.parent.join('example_response.json'))
    response = Wavefront::Response::Graphite.new(example_response)
    response_hash = JSON.parse(example_response)
    schema = interpolate_schema(response_hash['timeseries'][0]['label'], response_hash['timeseries'][0]['host'], 1)

    expect(response.graphite.size).to eq(21)
    expect(response.graphite[0].keys.size).to eq(2)
    expect(response.graphite[0]['target']).to eq(schema)
    expect(response.graphite[15]['datapoints'].size).to eq(31)
  end
end

describe Wavefront::Response::Highcharts do
  it 'returns something that resembles highcharts output' do
    example_response = File.read(Pathname.new(__FILE__).parent.parent.join('example_response.json'))
    response = Wavefront::Response::Highcharts.new(example_response)

    expect(response.highcharts[0]['data'].size).to eq(30)
    JSON.parse(response.to_json).each { |m| expect(m.keys.size).to eq(2) }
  end
end
