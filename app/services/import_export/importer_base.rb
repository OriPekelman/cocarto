require "csv"

module ImportExport
  class ImporterBase
    # @options:
    # - author
    # - stream: bool
    def initialize(layer, input, **options)
      @layer = layer
      @input = input
      @mapping = options[:mapping] || ImportExport.default_field_mapping(layer)
      @key_field = options[:key_field]
      @author = options[:author]
      @stream = options[:stream]
    end

    def import
      ApplicationRecord.transaction { import_rows }
    end

    # implemented by subclasses
    def import_rows = raise NotImplementedError
  end
end
