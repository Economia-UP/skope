source("r/mc_mxnusd.R")

testthat::test_that("mc_mxnusd outputs CSVs with rows", {
  testthat::expect_true(file.exists("data/mc_mxnusd_month.csv"))
  testthat::expect_true(file.exists("data/mc_mxnusd_5y.csv"))

  month <- readr::read_csv("data/mc_mxnusd_month.csv", show_col_types = FALSE)
  five_years <- readr::read_csv("data/mc_mxnusd_5y.csv", show_col_types = FALSE)

  testthat::expect_gt(nrow(month), 0)
  testthat::expect_gt(nrow(five_years), 0)
})
