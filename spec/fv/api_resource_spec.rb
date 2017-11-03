require 'spec_helper'

describe FV::ApiResource do
  describe '.resource_type' do
    it 'returns underscored, pluralized name' do
      expect(TestSdk::FooBar.resource_type).to eq('foo_bars')
    end
  end

  describe '.resource_path' do
    it 'returns underscored, pluralized path' do
      expect(TestSdk::FooBar.resource_path).to eq('/foo_bars')
    end
  end

  describe '.create' do
    it 'sends post request' do
      fake_response = double(FV::HttpResponse)
      allow(fake_response).to receive(:data).and_return({})
      allow_any_instance_of(FV::Client).to(
        receive(:request)
          .with(:post, '/foo_bars', body: anything)
          .and_return(fake_response)
      )

      resource = TestSdk::FooBar.create(some_attribute: 'hi mom')

      expect(resource).to be_a(TestSdk::FooBar)
    end
  end

  describe '.all' do
    it 'sends get all request' do
      fake_response = double(FV::HttpResponse)
      allow(fake_response).to receive(:data).and_return([{}, {}])
      allow_any_instance_of(FV::Client).to(
        receive(:request)
          .with(:get, '/foo_bars', params: {})
          .and_return(fake_response)
      )

      resources = TestSdk::FooBar.all

      expect(resources).to be_an(Array)
      expect(resources.count).to eq(2)
      expect(resources.first).to be_a(TestSdk::FooBar)
    end
  end

  describe '.where' do
    it 'sends get request' do
      fake_response = double(FV::HttpResponse)
      allow(fake_response).to receive(:data).and_return([{}, {}])
      allow_any_instance_of(FV::Client).to(
        receive(:request)
          .with(:get, '/foo_bars', params: {})
          .and_return(fake_response)
      )

      resources = TestSdk::FooBar.where

      expect(resources).to be_an(Array)
      expect(resources.count).to eq(2)
      expect(resources.first).to be_a(TestSdk::FooBar)
    end

    it 'allows filtering' do
      fake_response = double(FV::HttpResponse)
      allow(fake_response).to receive(:data).and_return([{}, {}])
      allow_any_instance_of(FV::Client).to(
        receive(:request)
          .with(
            :get,
            '/foo_bars',
            params: { filter: { some_filter: 'hi', other_filter: 123 }}
          )
          .and_return(fake_response)
      )

      resources = TestSdk::FooBar.where(some_filter: 'hi', other_filter: 123)

      expect(resources).to be_an(Array)
      expect(resources.count).to eq(2)
      expect(resources.first).to be_a(TestSdk::FooBar)
    end
  end

  describe '.find' do
    it 'sends find request' do
      fake_response = double(FV::HttpResponse)
      allow(fake_response).to receive(:data).and_return({})
      allow_any_instance_of(FV::Client).to(
        receive(:request)
          .with(:get, '/foo_bars/5')
          .and_return(fake_response)
      )

      resources = TestSdk::FooBar.find(5)

      expect(resources).to be_a(TestSdk::FooBar)
    end
  end

  describe '#path' do
    it 'returns path for specific resource' do
      resource = TestSdk::FooBar.new(id: 3)

      expect(resource.path).to eq('/foo_bars/3')
    end
  end

  describe '.save' do
    it 'updates attributes based on server response' do
      fake_response = double(FV::HttpResponse)
      allow(fake_response).to(
        receive(:data).and_return(attributes: { 'name' => 'server response' })
      )
      allow_any_instance_of(FV::Client).to(
        receive(:request)
          .with(:patch, '/foo_bars/3', body: {
            id: 3,
            type: 'foo_bars',
            attributes: { 'name' => 'changed' }
          }.to_json)
          .and_return(fake_response)
      )

      resource = TestSdk::FooBar.new(
        id: 3,
        attributes: { 'name' => 'original' }
      )
      resource.name = 'changed'
      resource.save

      expect(resource.name).to eq('server response')
    end
  end

  describe '.has_many' do
    before(:each) do
      @resource = TestSdk::Foo.new(id: 1)
    end

    it 'creates method for relationship' do
      expect(@resource.foo_bars).to be_an(FV::HasManyAssociation)
    end

    it 'allows appending without saving' do
      @resource.foo_bars << TestSdk::FooBar.new(id: 5)

      expect(@resource.foo_bars).to be_an(FV::HasManyAssociation)
      expect(@resource.foo_bars).to be_modified
    end

    it 'saves associations by hitting relationships url' do
      association_response = double(successful?: true)
      allow(TestSdk).to receive(:request).and_return(association_response)

      @resource.foo_bars << TestSdk::FooBar.new(id: 5)
      @resource.save

      expect(TestSdk).to(
        have_received(:request)
          .with(
            :post,
            '/foos/1/relationships/foo_bars',
            body: {
              data: [{ id: 5, type: 'foo_bars' }]
            }.to_json
          )
      )
      expect(@resource.foo_bars).not_to be_modified
    end

    it 'ignores appending duplicate relationships' do
      association_response = double(successful?: true)
      allow(TestSdk).to receive(:request).and_return(association_response)

      @resource.foo_bars << TestSdk::FooBar.new(id: 5)
      @resource.foo_bars << TestSdk::FooBar.new(id: 5)
      @resource.save

      expect(@resource.foo_bars).to be_an(FV::HasManyAssociation)
      expect(@resource.foo_bars).not_to be_modified
      expect(TestSdk).to(
        have_received(:request)
          .with(
            :post,
            '/foos/1/relationships/foo_bars',
            body: {
              data: [{ id: 5, type: 'foo_bars' }]
            }.to_json
          )
      )
    end

    it 'ignores errors if relationship already exists' do
      allow(TestSdk).to(
        receive(:request).and_raise(FV::RelationExistsError, {})
      )

      @resource.foo_bars << TestSdk::FooBar.new(id: 5)
      result = @resource.save

      expect(result).to be_a(TestSdk::Foo)
      expect(result).not_to be_modified
    end

    it 'delegates unknown messages to lazy-loaded resource collection' do
      allow(TestSdk).to(
        receive(:request).and_return(double(data: [{ id: 2 }, { id: 9 }]))
      )

      result = @resource.foo_bars.count

      expect(TestSdk).to have_received(:request)
      expect(result).to eq(2)
      expect(@resource.foo_bars.first).to be_a(TestSdk::FooBar)
      expect(@resource.foo_bars.first.id).to eq(2)
    end
  end

  describe '.belongs_to' do
    before(:each) do
      @resource = TestSdk::BelongsToResource.new(id: 1)
    end

    it 'creates method for accessing relationship' do
      allow(TestSdk).to receive(:request).and_return(double(data: {}))

      result = @resource.foo_bar

      expect(TestSdk).to(
        have_received(:request)
          .with(
            :get,
            '/belongs_to_resources/1/foo_bar'
          )
      )
      expect(result).to be_a(TestSdk::FooBar)
    end
  end

  module TestSdk
    extend FV::Client
    class FooBar < FV::ApiResource
      define_attribute_readers :name
    end

    class BelongsToResource < FV::ApiResource
      belongs_to :foo_bar
    end

    class Foo < FV::ApiResource
      has_many :foo_bars
    end
  end

  before(:all) do
    TestSdk.configure do |config|
      config.api_url = 'https://test-url.com'
      config.api_token = 'test-token'
    end
  end
end
