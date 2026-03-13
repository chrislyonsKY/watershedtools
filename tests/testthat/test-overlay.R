sites <- sf::st_read(
  system.file("extdata", "elkhorn_sites.geojson", package = "watershedtools"),
  quiet = TRUE
)
basin <- sf::st_read(
  system.file("extdata", "elkhorn_basin.geojson", package = "watershedtools"),
  quiet = TRUE
)

test_that("overlay_features joins sites to basin", {
  result <- overlay_features(sites, basin)
  expect_s3_class(result, "sf")
  expect_gte(nrow(result), nrow(sites))
  # Basin attributes should be attached
  expect_true("huc8" %in% names(result))
})

test_that("overlay_features with join='within' works", {
  result <- overlay_features(sites, basin, join = "within")
  expect_s3_class(result, "sf")
})

test_that("overlay_features with join='nearest' works", {
  result <- overlay_features(sites, basin, join = "nearest")
  expect_s3_class(result, "sf")
  expect_equal(nrow(result), nrow(sites))
  # All sites get a match with 'nearest'
  expect_false(any(is.na(result$huc8)))
})

test_that("overlay_features left-joins (keeps unmatched features)", {
  # Create a point outside the basin
  outside_pt <- sf::st_sf(
    site_id = "outside",
    name = "Outside Point",
    geometry = sf::st_sfc(sf::st_point(c(-80.0, 35.0)), crs = 4326)
  )
  all_sites <- rbind(
    sites[, c("site_id", "name", "geometry")],
    outside_pt
  )
  result <- overlay_features(all_sites, basin)
  # The outside point should have NA for basin columns
  outside_row <- result[result$site_id == "outside", ]
  expect_true(is.na(outside_row$huc8))
})

test_that("overlay_features errors for bad inputs", {
  expect_error(overlay_features("not_sf", basin), "sf data frame")
  expect_error(overlay_features(sites, "not_sf"), "sf data frame")
})

test_that("overlay_features rejects invalid join type", {
  expect_error(overlay_features(sites, basin, join = "bad"))
})
