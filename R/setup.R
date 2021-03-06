
setup_script_files <- function(options) {
  within(options, {
    func_file   <- save_function_to_temp(options)
    result_file <- tempfile()
    script_file <- make_vanilla_script_file(
      func_file, result_file, options$error)
    tmp_files <- c(tmp_files, func_file, script_file, result_file)
  })
}

save_function_to_temp <- function(options) {
  tmp <- tempfile()
  environment(options$func) <- .GlobalEnv
  saveRDS(list(options$func, options$args), file = tmp)
  tmp
}

setup_context <- function(options) {

  ## Avoid R CMD check warning...
  repos <- libpath <- system_profile <- user_profile <- load_hook <- NULL

  within(options, {
    ## profiles
    profiles <- make_profiles(system_profile, user_profile, repos, libpath,
                             load_hook)
    tmp_files <- c(tmp_files, profiles)

    ## environment files
    envs <- make_environ(profiles)
    tmp_files <- c(tmp_files, envs)
    
    if (is.na(env["R_ENVIRON"])) env["R_ENVIRON"] <- envs[[1]]
    if (is.na(env["R_ENVIRON_USER"])) env["R_ENVIRON_USER"] <- envs[[2]]
    if (is.na(env["R_PROFILE"])) env["R_PROFILE"] <- profiles[[1]]
    if (is.na(env["R_PROFILE_USER"])) env["R_PROFILE_USER"] <- profiles[[2]]
  })
}

make_profiles <- function(system, user, repos, libpath, load_hook) {

  profile_system <- tempfile()
  profile_user <- tempfile()

  ## Create file2
  cat("", file = profile_system)
  cat("", file = profile_user)

  ## Add profiles
  if (system) {
    sys <- Sys.getenv("R_PROFILE",
                      file.path(R.home("etc"), "Rprofile.site"))
    sys <- path.expand(sys)
    if (file.exists(sys)) file.append(profile_system, sys)
  }

  if (user) {
    user <- Sys.getenv("R_PROFILE_USER", NA_character_)
    local <- ".Rprofile"
    home  <- path.expand("~/.Rprofile")
    if (is.na(user) && file.exists(local)) user <- local
    if (is.na(user) && file.exists(home)) user <- home
    if (!is.na(user) && file.exists(user)) file.append(profile_user, user)
  }

  ## Override repos, as requested
  for (p in c(profile_system, profile_user)) {
    cat("options(repos=", deparse(repos), ")\n", sep = "", file = p,
        append = TRUE)
  }

  ## Set .Library.site
  cat(".Library.site <- ", deparse(.Library.site),
      "\n.libPaths(.libPaths())\n", file = profile_system, append = TRUE)

  ## Set .libPaths()
  for (p in c(profile_system, profile_user))  {
    cat(".libPaths(", deparse(libpath), ")\n", sep = "", file = p,
        append = TRUE)
  }

  if (!is.null(load_hook)) {
    cat(load_hook, sep = "",  file = profile_user, append = TRUE)
  }

  c(profile_system, profile_user)
}

make_environ <- function(profiles) {

  env_sys <- tempfile()
  env_user <- tempfile()

  sys <- Sys.getenv("R_ENVIRON", NA_character_)
  if (is.na(sys)) sys <- file.path(R.home("etc"), "Renviron.site")
  if (!is.na(sys) && file.exists(sys)) file.append(env_sys, sys)

  user <- Sys.getenv("R_ENVIRON_USER", NA_character_)
  local <- ".Renviron"
  home <- "~/.Renviron"
  if (is.na(user) && file.exists(local)) user <- local
  if (is.na(user) && file.exists(home)) user <- home
  if (!is.na(user) && file.exists(user))  file.append(env_user, user)

  for (ef in c(env_sys, env_user)) {
    cat("R_PROFILE=\"", profiles[[1]], "\"\n", file = ef,
        append = TRUE, sep = "")
    cat("R_PROFILE_USER=\"", profiles[[2]], "\"\n", file = ef,
        append = TRUE, sep = "")
  }

  c(env_sys, env_user)
}

setup_callbacks <- function(options) {

  ## We cannot easily use `within` here, because the
  ## functions we create will have the wrong environment

  cb <- options$callback
  block_cb <- options$block_callback

  ## This is cumbersome, because we cannot easily set a named list
  ## element to NULL
  options <- append(
    options,
    list("real_block_callback" =
           if (!is.null(block_cb)) function(x, proc) block_cb(x))
  )

  callback_factory <- function(stream) {
    ## Need to evaluate it when the callback is created
    force(stream)

    ## In case there is no output, we create an empty file here
    if (!is.null(stream)) cat("", file = stream)

    if (!is.null(cb)) {
      function(x, proc) {
        if (!is.null(stream)) cat(x, file = stream, sep = "\n", append = TRUE)
        cb(x)
      }

    } else {
      function(x, proc) {
        if (!is.null(stream)) cat(x, file = stream, sep = "\n", append = TRUE)
      }
    }
  }

  options <- append(options, list("real_callback" = callback_factory))
  options
}

setup_r_binary_and_args <- function(options, script_file = TRUE) {
  exec <- if (os_platform() == "windows") "Rterm" else "R"
  options$bin <- file.path(R.home("bin"), exec)
  options$real_cmdargs <-
    c(options$cmdargs, if (script_file) c("-f", options$script_file))
  options
}

setup_rcmd_binary_and_args <- function(options) {

  if(os_platform() == "windows") {
    options$bin <- file.path(R.home("bin"), "Rcmd.exe")
    options$real_cmdargs <- c(options$cmd, options$cmdargs)

  } else {
    options$bin <- file.path(R.home("bin"), "R")
    options$real_cmdargs <- c("CMD", options$cmd, options$cmdargs)
  }

  options
}
