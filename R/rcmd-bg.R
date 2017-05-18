
#' Run an R CMD command in the background
#'
#' The child process is started in the background, and the function
#' return immediately.
#'
#' @inheritParams rcmd
#' @return It returns a [processx::process] object.
#'
#' @family R CMD commands
#' @export
#' @importFrom processx process

rcmd_bg <- function(cmd, cmdargs = character(), libpath = .libPaths(),
                    stdout = "|", stderr = "|", repos = getOption("repos"),
                    system_profile = FALSE, user_profile = FALSE,
                    env = character(), wd = ".") {

  rcmd_process$new(options = as.list(environment()))
}

#' @export
#' @rdname rcmd_bg
#' @param ... Additional arguments are passed to [rcmd_bg()].

rcmd_bg_safe <- function(cmd, cmdargs = character(), libpath = .libPaths(),
                         stdout = "|", stderr = "|",
                         repos = c(getOption("repos"),
                           c(CRAN = "https://cran.rstudio.com")),
                         system_profile = FALSE, user_profile = FALSE,
                         env = rcmd_safe_env(), ...) {

  rcmd_bg(cmd, cmdargs = cmdargs, libpath = libpath, stdout = stdout,
          stderr = stderr, repos = repos, system_profile = system_profile,
          user_profile = user_profile, env = env, ...)
}