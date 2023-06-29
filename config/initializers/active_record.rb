Rails.application.config.after_initialize do
  ActiveRecord.yaml_column_permitted_classes += [
    Import::Report::RowResult
  ]
end
