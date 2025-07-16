node 'supabase-1.us-central1-f.c.tools-441408.internal' {
  class { 'supabase':
    postgres_password    => 'Trouble-Else-Wake-Shorten-6',
    
    # FIXED: Extended JWT secret to 40+ characters
    jwt_secret          => 'Wash-Basic-Letter-Run-Whistle-Try-Shout-4-Extended',
    
    # TODO: Replace these with REAL JWT tokens generated from jwt.io
    # Current tokens are INVALID examples that won't work!
    # 
    # Steps to generate real tokens:
    # 1. Go to https://jwt.io
    # 2. Use Algorithm: HS256
    # 3. Set your JWT secret: Wash-Basic-Letter-Run-Whistle-Try-Shout-4-Extended
    # 4. For anon_key, use payload:
    #    {
    #      "iss": "supabase",
    #      "ref": "anon", 
    #      "role": "anon",
    #      "iat": 1646067262,
    #      "exp": 1961643262
    #    }
    # 5. For service_role_key, use payload:
    #    {
    #      "iss": "supabase",
    #      "ref": "service_role",
    #      "role": "service_role", 
    #      "iat": 1646067262,
    #      "exp": 1961643262
    #    }
    
    anon_key            => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFub24iLCJyb2xlIjoiYW5vbiIsImlhdCI6MTY0NjA2NzI2MiwiZXhwIjoxOTYxNjQzMjYyfQ.REPLACE_THIS_WITH_REAL_TOKEN',
    service_role_key    => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNlcnZpY2Vfcm9sZSIsInJvbGUiOiJzZXJ2aWNlX3JvbGUiLCJpYXQiOjE2NDYwNjcyNjIsImV4cCI6MTk2MTY0MzI2Mn0.REPLACE_THIS_WITH_REAL_TOKEN',
    
    domain_name         => 'supabase.inventivehq.com',
    dashboard_username  => 'admin',
    dashboard_password  => 'Trouble-Else-Wake-Shorten-6',
    
    # Start with basic configuration (no SSL for initial testing)
    enable_ssl          => false,
  }
} 