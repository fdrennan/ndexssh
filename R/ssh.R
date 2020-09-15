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

#' @param remote_path An remote_path From path
#' @param local_path An local_path To Path
#' @param hostname Hostname of server
#' @param username Username for server
#' @param password Password for server, not required if passing keyfile
#' @param keyfile keyfile for server, required if not passing password
#' @export send_file
send_file <- function(local_path = NULL,
                      remote_path = NULL,
                      hostname = '192.168.0.51',
                      username = 'fdrennan',
                      password = 'thirdday1',
                      keyfile = '~/fdren.pem') {
  con <- get_ssh(hostname = hostname,
                 username = username,
                 password = password,
                 keyfile = keyfile)
  ftp_client = con$open_sftp()
  ftp_client$put(local_path, remote_path)
  ftp_client$close()
  ftp_client
}

#' @param local_path An local_path To Path
#' @param remote_path An remote_path From path
#' @param hostname Hostname of server
#' @param username Username for server
#' @param password Password for server, not required if passing keyfile
#' @param keyfile keyfile for server, required if not passing password
#' @export get_file
get_file <- function(local_path = NULL,
                     remote_path = NULL,
                     hostname = '192.168.0.51',
                     username = 'fdrennan',
                     password = 'thirdday1',
                     keyfile = '~/fdren.pem') {
  con <- get_ssh(hostname = hostname,
                 username = username,
                 password = password,
                 keyfile = keyfile)
  ftp_client = con$open_sftp()
  ftp_client$get(remote_path, local_path)
  ftp_client$close
  ftp_client
}

#' @param hostname Hostname of server
#' @param username Username for server
#' @param password Password for server, not required if passing keyfile
#' @param keyfile keyfile for server, required if not passing password
#' @importFrom reticulate import
#' @export get_ssh
get_ssh <- function(hostname = '192.168.0.51',
                    username = 'fdrennan',
                    password = 'thirdday1',
                    keyfile = NULL) {

  paramiko <- import('paramiko')
  ssh = paramiko$SSHClient()
  ssh$load_system_host_keys()
  ssh$set_missing_host_key_policy(paramiko$AutoAddPolicy())

  if (is.null(keyfile)) {
    ssh$connect(hostname=hostname,
                username=username,
                password=password)
  } else {
    ssh$connect(hostname=hostname,
                username=username,
                key_filename=keyfile)
  }

  ssh
}

#' @param hostname Hostname of server
#' @param username Username for server
#' @param password Password for server, not required if passing keyfile
#' @param keyfile keyfile for server, required if not passing password
#' @importFrom renv use_python
#' @importFrom reticulate import
#' @importFrom purrr map
#' @export execute_command_to_server
execute_command_to_server <-
  function(hostname = 'ec2-18-224-40-12.us-east-2.compute.amazonaws.com',
           username = 'ubuntu',
           password = 'password',
           keyfile = '/Users/fdrennan/fdren.pem',
           command = 'ls') {


    ssh <- get_ssh(hostname = hostname,
                   username = username,
                   password = password,
                   keyfile = keyfile)
    on.exit({
      ssh$close()
    })

    response <- ssh$exec_command(command)

    message(command)
    responses <-
      map(response[2:3],
        function(response_level) {
          response <- tryCatch({
            response <- as.character(response_level$read())
            response
          }, error = function(err) {
            return('false')
          })
          response
        })

    map(responses, cat)

    responses

  }


#' @param hostname Hostname of server
#' @param username Username for server
#' @param keyfile keyfile for server, required if not passing password
#' @param password Password for server, not required if passing keyfile
#' @param local_path Path to script
#' @importFrom glue glue
#' @export pass_script
pass_script <- function(hostname = 'ec2-18-224-40-12.us-east-2.compute.amazonaws.com',
                        username = 'ubuntu',
                        keyfile = '/Users/fdrennan/fdren.pem',
                        password = 'password',
                        local_path = 'test.sh',
                        as_sudo = FALSE) {

  responses <-
    send_file(hostname = hostname,
              username = username,
              password = password,
              keyfile = keyfile,
              local_path = local_path,
              remote_path = glue('/home/ubuntu/{local_path}'))


  script_path <- glue('sh {local_path}')
  script_path <- ifelse(as_sudo, paste('sudo', script_path), script_path)

  responses <-
    execute_command_to_server(hostname = hostname,
                              username = username,
                              password = password,
                              keyfile = keyfile,
                              command = script_path)

  responses

}


# command_block <-
#   c(
#     "ls -lah",
#     "sudo apt-get update -y",
#     "git clone https://github.com/fdrennan/docker_pull_postgres.git || echo '\nDirectory already exists..\n'",
#     "docker-compose -f docker_pull_postgres/docker-compose.yml pull",
#     "docker-compose -f docker_pull_postgres/docker-compose.yml down",
#     "docker-compose -f docker_pull_postgres/docker-compose.yml up -d",
#     "docker container ls"
#   )
#
# purrr::map(
#   command_block,
#   ~ {
#     execute_command_to_server(command = .)
#   }
# )
