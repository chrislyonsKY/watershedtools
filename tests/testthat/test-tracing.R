# Load sample flowlines once for all tests
flowlines <- sf::st_read(

  system.file("extdata", "elkhorn_flowlines.geojson", package = "watershedtools"),
  quiet = TRUE
)

# ---- trace_upstream ---------------------------------------------------------

test_that("trace_upstream finds all upstream segments from confluence", {
  result <- trace_upstream(flowlines, comid = 9734460)
  expect_s3_class(result, "sf")
  # Should include: N Elkhorn head & mid, S Elkhorn head & mid, plus Elkhorn main
  expect_equal(sort(result$comid), sort(c(9734444, 9734446, 9734452, 9734454, 9734460)))
})

test_that("trace_upstream from headwater returns only that segment", {
  result <- trace_upstream(flowlines, comid = 9734444)
  expect_equal(nrow(result), 1L)
  expect_equal(result$comid, 9734444)
})

test_that("trace_upstream from outlet returns entire network", {
  result <- trace_upstream(flowlines, comid = 9734472)
  expect_equal(nrow(result), nrow(flowlines))
})

test_that("trace_upstream errors for missing COMID", {
  expect_error(trace_upstream(flowlines, comid = 9999999), "not found")
})

test_that("trace_upstream errors for non-sf input", {
  expect_error(trace_upstream(data.frame(x = 1), comid = 1), "sf data frame")
})

test_that("trace_upstream errors for missing columns", {
  bad <- flowlines
  bad$hydroseq <- NULL
  expect_error(trace_upstream(bad, comid = 9734460), "missing required columns")
})

# ---- trace_downstream -------------------------------------------------------

test_that("trace_downstream follows N Elkhorn to outlet", {
  result <- trace_downstream(flowlines, comid = 9734444)
  expect_s3_class(result, "sf")
  # N Elkhorn head → N Elkhorn mid → Elkhorn main → Elkhorn lower → mouth
  expect_equal(
    sort(result$comid),
    sort(c(9734444, 9734446, 9734460, 9734468, 9734472))
  )
})

test_that("trace_downstream from outlet returns only that segment", {
  result <- trace_downstream(flowlines, comid = 9734472)
  expect_equal(nrow(result), 1L)
  expect_equal(result$comid, 9734472)
})

test_that("trace_downstream follows S Elkhorn to outlet", {
  result <- trace_downstream(flowlines, comid = 9734452)
  expect_equal(
    sort(result$comid),
    sort(c(9734452, 9734454, 9734460, 9734468, 9734472))
  )
})

test_that("trace_downstream errors for missing COMID", {
  expect_error(trace_downstream(flowlines, comid = 9999999), "not found")
})
