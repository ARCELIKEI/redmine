# Add new mime types for use in respond_to blocks:

Mime::SET << Mime::CSV unless Mime::SET.include?(Mime::CSV)

Mime::Type.register 'application/vnd.ms-excel', :xls
