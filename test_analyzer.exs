#!/usr/bin/env elixir
# Run with: mix run test_analyzer.exs

defmodule AnalyzerTest do
  def run do
    menu_live_path = "test/fixtures/test_menu_live.ex"
    dashboard_live_path = "test/fixtures/test_dashboard_live.ex"
    partial_live_path = "test/fixtures/test_partial_live.ex"

    # Get the file contents
    menu_live_content = File.read!(menu_live_path)
    dashboard_live_content = File.read!(dashboard_live_path)
    partial_live_content = File.read!(partial_live_path)

    # Define config with required sections
    config = [
      required: [
        "LIFECYCLE CALLBACKS",
        "EVENT HANDLERS",
        "RENDERING"
      ]
    ]

    # Test the analyzer on all files
    IO.puts("\n\n===== Testing MenuLive (should have no missing sections) =====")
    menu_violations = ExCodeAudit.Analyzers.LiveView.check(menu_live_path, menu_live_content, config)

    if Enum.empty?(menu_violations) do
      IO.puts("✅ Success: No violations found in MenuLive as expected")
    else
      IO.puts("❌ Failure: Found violations in MenuLive (expected none):")
      Enum.each(menu_violations, fn violation ->
        IO.puts("  - #{violation.message}")
      end)
    end

    IO.puts("\n\n===== Testing DashboardLive (should have missing sections) =====")
    dashboard_violations = ExCodeAudit.Analyzers.LiveView.check(dashboard_live_path, dashboard_live_content, config)

    if Enum.empty?(dashboard_violations) do
      IO.puts("❌ Failure: No violations found in DashboardLive (expected some)")
    else
      IO.puts("✅ Success: Found violations in DashboardLive as expected:")
      Enum.each(dashboard_violations, fn violation ->
        IO.puts("  - #{violation.message}")
      end)
    end

    IO.puts("\n\n===== Testing PartialLive (should only flag LIFECYCLE CALLBACKS) =====")
    partial_violations = ExCodeAudit.Analyzers.LiveView.check(partial_live_path, partial_live_content, config)

    if Enum.empty?(partial_violations) do
      IO.puts("❌ Failure: No violations found in PartialLive (expected LIFECYCLE CALLBACKS)")
    else
      IO.puts("✅ Checking violations found in PartialLive:")
      Enum.each(partial_violations, fn violation ->
        IO.puts("  - #{violation.message}")

        # Only LIFECYCLE CALLBACKS should be missing, not EVENT HANDLERS
        if String.contains?(violation.message, "EVENT HANDLERS") do
          IO.puts("❌ Failure: EVENT HANDLERS was flagged but shouldn't be")
        else
          IO.puts("✅ Success: Only necessary sections were flagged")
        end
      end)
    end
  end
end

AnalyzerTest.run()
