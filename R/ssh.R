#' @importFrom renv use_python
#' @importFrom reticulate conda_install
#' @export install_python
install_python <- function() {
  use_python(type = "conda")
  conda_install(packages = c(
    c('paramiko', 'boto3')
  ))
}


#' @importFrom reticulate import iterate
#' @importFrom tibble tibble
#' @importFrom purrr map_df
#' @export read_env
read_env <- function(){
  map_df(
    iterate(import('os')$environ), function(x) {
      tibble(
        key = x,
        value = import('os')$environ[x]
      )
    }
  )
}

#' @importFrom renv use_python
#' @importFrom reticulate import
#' @export execute_commaned_to_server
execute_commaned_to_server <-
  function(hostname = '192.168.0.51',
           username = 'fdrennan',
           password = 'thirdday1',
           command = 'ls') {

  paramiko <- import('paramiko')
  client = paramiko$SSHClient()
  client$load_system_host_keys()
  client$set_missing_host_key_policy(paramiko$AutoAddPolicy())
  client$connect(hostname=hostname, username=username, password=password)
  client$exec_command(command)
}

