# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_thesis_session',
  :secret      => '205c74654ff7ecdd5afffd03e73d25b61af7aa47a93c76a06daa4f2de009fa62ab5fb98e1a9e9e491eef03e56a56c7d70be3eba4acffa8660628e712793e80f4'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
