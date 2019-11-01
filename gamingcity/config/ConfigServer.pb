port: 7999 
config_db {
  host: "tcp://127.0.0.1:3306"
  user: "root"
  password: "123456"
  database: "config"
}
log_print_open:true
account_db {
  host: "tcp://127.0.0.1:3306"
  user: "root"
  password: "123456"
  database: "account"
}