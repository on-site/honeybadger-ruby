require 'pathname'
require 'yaml'
require 'erb'

module Honeybadger
  class Config
    module Yaml
      DISALLOWED_KEYS = [:'config.path'].freeze

      def self.new(path, env = 'production')
        path = path.kind_of?(Pathname) ? path : Pathname.new(path)

        if !path.exist?
          raise ConfigError, "The configuration file #{path} was not found."
        elsif !path.file?
          raise ConfigError, "The configuration file #{path} is not a file."
        elsif !path.readable?
          raise ConfigError, "The configuration file #{path} is not readable."
        end

        yaml = load_yaml(path)
        yaml.merge!(yaml[env]) if yaml[env].kind_of?(Hash)

        dotify_keys(yaml)
      end

      def self.load_yaml(path)
        yaml = YAML.load(ERB.new(path.read).result)
        case yaml
        when Hash
          yaml
        when NilClass, FalseClass
          {}
        else
          raise ConfigError, "The configuration file #{path} is invalid."
        end
      end

      def self.dotify_keys(hash, key_prefix = nil)
        {}.tap do |new_hash|
          hash.each_pair do |k,v|
            k = [key_prefix, k].compact.join('.')
            if v.kind_of?(Hash)
              new_hash.update(dotify_keys(v, k))
            else
              next if DISALLOWED_KEYS.include?(k.to_sym)
              new_hash[k.to_sym] = v
            end
          end
        end
      end
    end
  end
end
