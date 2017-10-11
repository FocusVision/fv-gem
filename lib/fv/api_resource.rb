module FV
  class ApiResource
    # Query class methods
    def self.create(params = {})
      response = client.request(
        :post,
        resource_path,
        body: serialize(params)
      )
      new(response.data)
    end

    def self.find(id)
      response = client.request(:get, "#{resource_path}/#{id}")
      new(response.data)
    end

    def self.all
      where
    end

    def self.where(**filters)
      params = filters.empty? ? {} : { filter: filters }
      response = client.request(:get, resource_path, params: params)
      response.data.map(&method(:new))
    end

    # Class methods for API serialization
    def self.resource_path
      "/#{resource_type}"
    end

    def self.resource_type
      transform_key_for_api(name.demodulize.pluralize)
    end

    # Override to dasherize keys for your API
    def self.transform_key_for_api(key)
      key.to_s.underscore
    end

    def self.transform_hash_keys_for_api(hash)
      hash.map { |k, v| [transform_key_for_api(k), v] }.to_h
    end

    def self.serialize(attributes)
      {
        data: {
          type: resource_type,
          attributes: transform_hash_keys_for_api(attributes)
        }
      }.to_json
    end

    def self.define_attribute_readers(*attrs)
      attrs.each do |attribute|
        define_method(attribute) do
          attributes[self.class.transform_key_for_api(attribute)]
        end
      end
    end

    def self.has_many(*args)
      memoize_relationships(*args) do |relationship, to_resource_class|
        FV::HasManyAssociation.new(
          self,
          to_resource_class,
          relationship
        ).tap do |association|
          @associations << association
        end
      end
    end

    def self.belongs_to(*args)
      memoize_relationships(*args) do |relationship, to_resource_class|
        to_resource_class.new(
          self.class.client.request(:get, "#{path}/#{relationship}").data
        )
      end
    end

    def self.memoize_relationships(*args, &block)
      args.each do |relationship|
        define_method(relationship) do
          key = "@#{relationship}"
          return instance_variable_get(key) if instance_variable_defined?(key)

          value = instance_exec(
            relationship,
            resource_class_for_relationship(relationship),
            &block
          )

          instance_variable_set(key, value)
        end
      end
    end

    def resource_class_for_relationship(relationship)
      module_name = self.class.to_s.split('::')[0..-2].join('::')
      to_resource_classname = relationship.to_s.singularize.camelize
      "#{module_name}::#{to_resource_classname}".constantize
    end

    def self.client
      const_get(name.deconstantize)
    end

    attr_reader :id, :attributes, :meta, :links, :relationships

    def initialize(raw_data)
      @id = raw_data[:id].to_i
      @attributes = raw_data[:attributes]
      @meta = raw_data[:meta] || {}
      @links = raw_data[:links] || {}
      @relationships = raw_data[:relationships] || {}
      @associations = []
    end

    def to_hash
      serialized = {
        id: @id,
        type: self.class.resource_type,
        attributes: @attributes
      }
      serialized[:meta] = @meta unless @meta.empty?
      serialized[:links] = @links unless @links.empty?
      serialized[:relationships] = @relationships unless @relationships.empty?
      serialized
    end

    def save
      return self unless modified?
      @associations.each(&:save)
      self
    end

    def modified?
      @associations.any?(&:modified?)
    end

    def path
      "#{self.class.resource_path}/#{id}"
    end
  end
end
