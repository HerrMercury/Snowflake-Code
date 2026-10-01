---Create Secret for Personal Access Token
CREATE OR REPLACE SECRET github_token
  TYPE = PASSWORD
  USERNAME = 'HERRMERCURY'
  PASSWORD = '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';


---Create API intergartion for My GITHUB Account
CREATE OR REPLACE API INTEGRATION github_api_integration
API_PROVIDER = git_https_api
API_ALLOWED_PREFIXES = ('https://github.com/HerrMercury/')
ALLOWED_AUTHENTICATION_SECRETS = (github_token)
ENABLED = TRUE;