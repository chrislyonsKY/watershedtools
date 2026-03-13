# get_watershed requires nhdplusTools + internet — only test input validation

test_that("get_watershed errors when no arguments supplied", {
  skip_if_not_installed("nhdplusTools")
  expect_error(get_watershed(), "must be provided")
})

test_that("get_watershed errors when both point and comid supplied", {
  skip_if_not_installed("nhdplusTools")
  pt <- sf::st_sfc(sf::st_point(c(-84.87, 38.20)), crs = 4326)
  expect_error(get_watershed(point = pt, comid = 123), "not both")
})

test_that("get_watershed errors for non-sf point", {
  skip_if_not_installed("nhdplusTools")
  expect_error(get_watershed(point = "not_sf"), "sf or sfc")
})
