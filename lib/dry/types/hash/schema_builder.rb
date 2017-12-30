require 'dry/types/hash/schema'
require 'dry/types/fn_container'

module Dry
  module Types
    class Hash < Definition
      class SchemaBuilder
        def initialize
          @nil_to_undefined = -> v { v.nil? ? Undefined : v }
          @omittable_keys = %i(schema weak symbolized).freeze
          @permissive = %i(schema permissive weak symbolized).freeze

          freeze
        end

        def call(primitive, options)
          hash_type = options.fetch(:hash_type)
          member_types = {}

          options.fetch(:member_types).each do |k, t|
            member_types[k] = build_type(hash_type, t)
          end

          instantiate(primitive, **options, member_types: member_types)
        end

        def instantiate(primitive, hash_type: :base, meta: EMPTY_HASH, **options)
          meta = meta.dup

          meta[:permissive] = true if permissive?(hash_type)
          meta[:key_transform_fn] = Schema::SYMBOLIZE_KEY if hash_type == :symbolized

          Schema.new(primitive, **options, meta: meta)
        end

        private

        def omittable?(constructor)
          @omittable_keys.include?(constructor)
        end

        def permissive?(constructor)
          @permissive.include?(constructor)
        end

        def build_type(constructor, type)
          type = safe(constructor, type)
          type = default(constructor, type) if type.default?
          type = type.meta(omittable: true) if omittable?(constructor)
          type
        end

        def safe(constructor, type)
          if constructor == :weak || constructor == :symbolized
            type.safe
          else
            type
          end
        end

        def default(constructor, type)
          case constructor
          when :strict_with_defaults
            type
          when :strict
            type.type
          else
            type.constructor(@nil_to_undefined)
          end
        end
      end
    end
  end
end
