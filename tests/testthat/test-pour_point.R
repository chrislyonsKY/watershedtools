flowlines <- sf::st_read(
  system.file("extdata", "elkhorn_flowlines.geojson", package = "watershedtools"),
  quiet = TRUE
)

test_that("snap_pour_point snaps to nearest flowline", {
  pt <- sf::st_sf(
    geometry = sf::st_sfc(sf::st_point(c(-84.68, 38.155)), crs = 4326)
  )
  result <- snap_pour_point(pt, flowlines)

  expect_s3_class(result, "sf")
  expect_equal(nrow(result), 1L)
  expect_true("snap_distance" %in% names(result))
  expect_true("comid" %in% names(result))
  # Snap distance in metres (sf uses geodesic distance for WGS 84)
  # Point is near Elkhorn main segment, so should be < 1 km
  expect_lt(result$snap_distance, 1000)
})

test_that("snap_pour_point attaches flowline attributes", {
  pt <- sf::st_sf(
    geometry = sf::st_sfc(sf::st_point(c(-84.53, 38.14)), crs = 4326)
  )
  result <- snap_pour_point(pt, flowlines)
  # Should snap to N Elkhorn head or mid segment
  expect_true(result$comid %in% c(9734444, 9734446))
})

test_that("snap_pour_point respects tolerance", {
  # Point very far from any flowline
  pt <- sf::st_sf(
    geometry = sf::st_sfc(sf::st_point(c(-80.0, 35.0)), crs = 4326)
  )
  expect_error(snap_pour_point(pt, flowlines, tolerance = 100), "exceeding tolerance")
})

test_that("snap_pour_point errors for bad input types", {
  expect_error(snap_pour_point("not_sf", flowlines), "sf or sfc")
  pt <- sf::st_sf(
    geometry = sf::st_sfc(sf::st_point(c(-84.68, 38.155)), crs = 4326)
  )
  expect_error(snap_pour_point(pt, "not_sf"), "sf data frame")
})
