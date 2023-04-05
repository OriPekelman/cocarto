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
      @author = options[:author]
      @stream = options[:stream]
    end

    def import = import_rows

    def import_rows = raise NotImplementedError
  end
end
