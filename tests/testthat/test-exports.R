# Verify all exported functions exist and are callable

test_that("all exported functions exist", {
  expect_true(is.function(validate_huc))
  expect_true(is.function(huc_level))
  expect_true(is.function(parent_huc))
  expect_true(is.function(get_watershed))
  expect_true(is.function(trace_upstream))
  expect_true(is.function(trace_downstream))
  expect_true(is.function(snap_pour_point))
  expect_true(is.function(overlay_features))
})
