---@diagnostic disable: duplicate-set-field

local assert = require("luassert")
local xcode = require("xcodebuild.core.xcode")
local appdata = require("xcodebuild.project.appdata")

local busted = require("plenary.busted")
local before_each = busted.before_each
local after_each = busted.after_each
local it = busted.it
local describe = busted.describe

describe("xcodebuild.core.xcode", function()
  local originalJobstart
  local originalDelete
  local originalFindSchemes
  local command

  before_each(function()
    originalJobstart = vim.fn.jobstart
    originalDelete = vim.fn.delete
    originalFindSchemes = xcode.find_schemes
    command = nil

    appdata.build_xcresult_filepath = "/tmp/build.xcresult"
    appdata.test_xcresult_filepath = "/tmp/test.xcresult"
    appdata.tests_filepath = "/tmp/tests.json"

    vim.fn.delete = function() end
    vim.fn.jobstart = function(cmd, _)
      command = cmd
      return 1
    end
  end)

  after_each(function()
    vim.fn.jobstart = originalJobstart
    vim.fn.delete = originalDelete
    xcode.find_schemes = originalFindSchemes
  end)

  describe("resolve_derived_data_path", function()
    it("THEN returns nil for empty config", function()
      assert.are.equal(nil, xcode.resolve_derived_data_path(nil, "/project"))
      assert.are.equal(nil, xcode.resolve_derived_data_path("", "/project"))
    end)

    it("THEN resolves relative paths against working directory", function()
      assert.are.equal("/project/build", xcode.resolve_derived_data_path("build", "/project"))
    end)

    it("THEN keeps absolute paths", function()
      assert.are.equal("/tmp/build", xcode.resolve_derived_data_path("/tmp/build/", "/project"))
    end)
  end)

  describe("build_project", function()
    it("THEN passes derivedDataPath to xcodebuild", function()
      xcode.build_project({
        workingDirectory = "/project",
        projectFile = "App.xcodeproj",
        scheme = "App",
        destination = "device-id",
        derivedDataPath = "/project/build",
        extraBuildArgs = {},
      })

      assert.are.same({
        "xcodebuild",
        "build",
        "-derivedDataPath",
        "/project/build",
        "-project",
        "App.xcodeproj",
        "-scheme",
        "App",
        "-destination",
        "id=device-id",
        "-resultBundlePath",
        "/tmp/build.xcresult",
      }, command)
    end)
  end)

  describe("run_tests", function()
    it("THEN passes derivedDataPath to xcodebuild", function()
      xcode.run_tests({
        withoutBuilding = true,
        workingDirectory = "/project",
        projectFile = "App.xcodeproj",
        scheme = "App",
        destination = "device-id",
        derivedDataPath = "/project/build",
        extraTestArgs = {},
      })

      assert.are.same({
        "xcodebuild",
        "test-without-building",
        "-scheme",
        "App",
        "-destination",
        "id=device-id",
        "-derivedDataPath",
        "/project/build",
        "-project",
        "App.xcodeproj",
        "-resultBundlePath",
        "/tmp/test.xcresult",
      }, command)
    end)
  end)

  describe("enumerate_tests", function()
    it("THEN passes derivedDataPath to xcodebuild", function()
      xcode.enumerate_tests({
        workingDirectory = "/project",
        projectFile = "App.xcodeproj",
        scheme = "App",
        destination = "device-id",
        testPlan = "AppTests",
        derivedDataPath = "/project/build",
        extraTestArgs = {},
      })

      assert.are.same({
        "xcodebuild",
        "test-without-building",
        "-enumerate-tests",
        "-scheme",
        "App",
        "-destination",
        "id=device-id",
        "-derivedDataPath",
        "/project/build",
        "-project",
        "App.xcodeproj",
        "-testPlan",
        "AppTests",
        "-test-enumeration-format",
        "json",
        "-test-enumeration-output-path",
        "/tmp/tests.json",
        "-disableAutomaticPackageResolution",
        "-skipPackageUpdates",
        "-test-enumeration-style",
        "flat",
      }, command)
    end)
  end)

  describe("get_build_settings", function()
    it("THEN passes derivedDataPath to xcodebuild", function()
      xcode.find_schemes = function(_, _, callback)
        callback()
      end

      xcode.get_build_settings(
        "iOS Simulator",
        "App.xcodeproj",
        "App",
        "App.xcodeproj",
        "/project/build",
        function() end
      )

      assert.are.same({
        "xcodebuild",
        "build",
        "-project",
        "App.xcodeproj",
        "-scheme",
        "App",
        "-derivedDataPath",
        "/project/build",
        "-showBuildSettings",
        "-sdk",
        "iphonesimulator",
      }, command)
    end)
  end)
end)
