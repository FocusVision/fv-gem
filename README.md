# FV

The FV gem is a library for quickly building SDKs for JSONAPI-compliant APIs.

You can define resources and their corresponding attributes, and FV will
create a client for ActiveRecord-like actions on your API.

```ruby
# returns: [MySdk::MyResource, MySdk::MyResource, ...]
# query: `GET /my_resources`
MySdk::MyResource.all

# returns: MySdk::MyResource
# query: `GET /my_resources/:id`
MySdk::MyResource.find(123) # MyResource object with ID 123

# returns: [MySdk::MyResource, MySdk::MyResource, ...]
# query: `GET /my_resources?filter[name]=TestResource`
MySdk::MyResource.where(name: 'TestResource') # List of MyResource objects
```

### Usage

Include `FV::Client` in your top-level module.
```ruby
# lib/my_sdk.rb
require 'fv'
require 'my_sdk/resources/my_resource'

module MySdk
  extend FV::Client
end
```

Define a resource by inheriting from `FV::ApiResource` and specifying
attributes.
```ruby
# lib/my_sdk/resources/my_resource
module MySdk
  class MyResource < FV::ApiResource
    define_attribute_readers :name,
                             :attribute_a,
                             :attribute_b

    has_many :other_resources
    belongs_to :related_thing
  end
end
```

Initialize your SDK in an application.
```ruby
# initializers/my_sdk.rb
MySdk.configure do |config|
  config.api_url = 'https://test-url.com/api'
  config.api_token = 'test_token'
end
```

You're good to go!
```ruby
my_resources = MySdk::MyResource.all
my_resources.first.other_resources.first # MySdk::OtherResource
my_resources.first.related_thing # MySdk::RelatedThing
```
