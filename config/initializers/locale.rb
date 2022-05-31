# Où la bibliothèque I18n doit rechercher les fichiers de traduction
I18n.load_path += Dir[Rails.root.join("lib", "locale", "*.{rb,yml}")]

# Paramètres régionaux autorisés disponibles pour l'application
I18n.available_locales = [:en, :fr]
