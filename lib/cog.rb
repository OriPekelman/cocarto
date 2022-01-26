require "zip"
require "csv"

module Cog
  def self.import_cog
    URI.open("https://www.insee.fr/fr/statistiques/fichier/5057840/cog_ensemble_2021_csv.zip") do |zipped|
      Zip::File.open(zipped) do |zip_file|
        departements = zip_file.get_entry("departement2021.csv").get_input_stream.read
        deps = {}
        CSV.parse(departements, headers: true).each do |row|
          deps[row["DEP"]] = Departement.create(code: row["DEP"], libelle: row["LIBELLE"])
        end

        # What type of commune we want to keep:
        # normal communes (not « associées » or « déléguées »), but we keep the arrondissements
        type = ["COM", "ARM"]
        communes_csv = zip_file.get_entry("commune2021.csv").get_input_stream.read
        communes = CSV.parse(communes_csv, headers: true).select { |row| type.include?(row["TYPECOM"]) }.map { |row|
          {code: row["COM"], libelle: row["LIBELLE"], departement_id: deps[row["DEP"]].id, year: 2021}
        }
        Commune.insert_all(communes)
      end
    end
  end
end
