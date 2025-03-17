defmodule ExCodeAuditTest do
  use ExUnit.Case
  doctest ExCodeAudit

  test "greets the world" do
    assert ExCodeAudit.hello() == :world
  end
end
