class ImportData < Thor
  def self.exit_on_failure? = true

  desc "import", "Import to an existing layer"
  option :configuration, required: true, type: :string, aliases: :c, desc: "Preset Import::Configuration"
  option :file, required: false, type: :string, aliases: :f, desc: "Source file"
  option :url, required: false, type: :string, aliases: :u, desc: "Source url"
  def import
    operation = Import::Operation.new
    operation.configuration = Import::Configuration.find_by(id: options[:configuration])
    operation.configuration ||= Import::Configuration.find_by(name: options[:configuration])

    # Note: :file and :url are mutually exclusive but we rely on model validation to enforce this.
    operation.remote_source_url = options[:url]
    if options[:file].present?
      path = Pathname(options[:file])
      extension = path.extname[1..]
      operation.local_source_file = {io: path.open, filename: path.basename, content_type: Mime[extension]}
    end
    author = User.find_by(id: options[:author]) || operation.configuration.map.users.sample

    operation.save!

    operation.import!(author)
  end

  default_command :import
end
