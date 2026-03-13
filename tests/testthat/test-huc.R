# ---- validate_huc -----------------------------------------------------------

test_that("validate_huc accepts valid HUC codes at all levels", {
  hucs <- c("05", "0510", "051002", "05100205", "0510020501", "051002050101")
  expect_true(all(validate_huc(hucs)))
})

test_that("validate_huc accepts HUC2 regions starting with zero", {
  expect_true(validate_huc("01"))
  expect_true(validate_huc("09"))
})

test_that("validate_huc rejects invalid lengths", {
  expect_false(any(validate_huc(c("5", "123", "0510020", "0510020501011"))))
})

test_that("validate_huc rejects non-digit characters", {
  expect_false(validate_huc("0510ab"))
  expect_false(validate_huc("ABCDEF"))
  expect_false(validate_huc("05-100"))
})

test_that("validate_huc returns FALSE for NA input", {
  expect_false(validate_huc(NA_character_))
  expect_equal(validate_huc(c("05", NA_character_)), c(TRUE, FALSE))
})

test_that("validate_huc errors on numeric input", {
  expect_error(validate_huc(5100205), "character")
  expect_error(validate_huc(05), "character")
})

test_that("validate_huc errors on non-character types", {
  expect_error(validate_huc(TRUE), "character")
  expect_error(validate_huc(list("05")), "character")
})

test_that("validate_huc handles empty character vector", {
  expect_length(validate_huc(character(0)), 0L)
})

# ---- huc_level --------------------------------------------------------------

test_that("huc_level returns correct levels", {
  expect_equal(
    huc_level(c("05", "0510", "051002", "05100205", "0510020501", "051002050101")),
    c(2L, 4L, 6L, 8L, 10L, 12L)
  )
})

test_that("huc_level returns NA for invalid codes", {
  expect_equal(huc_level(c("05", "bad")), c(2L, NA_integer_))
})

# ---- parent_huc -------------------------------------------------------------

test_that("parent_huc truncates correctly", {
  expect_equal(parent_huc("051002050101", level = 8), "05100205")
  expect_equal(parent_huc("051002050101", level = 2), "05")
  expect_equal(parent_huc("05100205", level = 4), "0510")
})

test_that("parent_huc is vectorised", {
  expect_equal(
    parent_huc(c("05100205", "06030001"), level = 4),
    c("0510", "0603")
  )
})

test_that("parent_huc returns NA when level is not coarser", {
  expect_equal(parent_huc("05", level = 4), NA_character_)
  expect_equal(parent_huc("0510", level = 4), NA_character_)
})

test_that("parent_huc returns NA for invalid input", {
  expect_equal(parent_huc("bad", level = 4), NA_character_)
})

test_that("parent_huc rejects invalid level", {
  expect_error(parent_huc("05100205", level = 3), "must be one of")
  expect_error(parent_huc("05100205", level = 12), "must be one of")
})
