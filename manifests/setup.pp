node 'supabase.inventivehq.com' {
  class { 'supabase':
    postgres_password    => 'Trouble-Else-Wake-Shorten-6',
    jwt_secret          => 'Wash-Basic-Letter-Run-Whistle-Try-Shout-4',
    anon_key            => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFub24iLCJyb2xlIjoiYW5vbiIsImlhdCI6MTY0NjA2NzI2MiwiZXhwIjoxOTYxNjQzMjYyfQ.example',
    service_role_key    => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNlcnZpY2Vfcm9sZSIsInJvbGUiOiJzZXJ2aWNlX3JvbGUiLCJpYXQiOjE2NDYwNjcyNjIsImV4cCI6MTk2MTY0MzI2Mn0.example',
    domain_name         => 'supabase.inventivehq.com',
    dashboard_username  => 'admin',
    dashboard_password  => 'Trouble-Else-Wake-Shorten-6',
  }
}